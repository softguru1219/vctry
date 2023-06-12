namespace :toornament do
  desc "TODO"
  task setup: :environment do
    puts 'Worked crontab for toornament setup'
    tournament_id = nil
    tournaments = TournamentApi::DownUploadTournament.new.get_tournaments tournament_id

    if tournaments.present?
      # new_tournaments = tournaments.select {|tournament| tournament unless Tournament.where(toornament_id: tournament["id"])}
      tournaments.each do |tournament|
        save_tournament(tournament)
        sleep(5.seconds)
      end

      existing_tournaments = tournaments.select {|tournament| tournament if Tournament.where(toornament_id: tournament["id"])}
      uncompleted_tournaments = existing_tournaments.select{|tournament| tournament if tournament["status"] != "completed"}
      completed_tournaments = existing_tournaments.select{|tournament| tournament if tournament["status"] == "completed"}
      
      uncompleted_tournaments.each do |tournament|
        # Update Match data
        match_check_tournament(tournament)

        # Update stage data
        stage_check_tournament(tournament)

        sleep(5.seconds)
      end
      
      completed_tournaments.each do |tournament|
        # Update standing data
        standing_check_tournament(tournament)
        
        sleep(5.seconds)
      end
    end

    # Unsubscribe autopay 
    User.schedule_run_expired_auto_unsubscribe

    # Unsubscribe subscription
    User.schedule_run_expired_subscription_unsubscribe
  end

  # Save the tournament
  def save_tournament(tournament)
    if tournament["status"] == "completed"
      existing_tournament = Tournament.find_by(toornament_id: tournament["id"])
      if existing_tournament
        existing_tournament.update(status: "completed")
      end
    else
      toornament = TournamentApi::DownUploadTournament.new.get_single_tournaments tournament.symbolize_keys[:id]
      begin
        params = toornament.symbolize_keys
        params[:toornament_id] = params.delete :id
        params[:timezone] = 'UTC'
        
        existing_tournament = Tournament.find_by(toornament_id: params[:toornament_id])
        if existing_tournament
          if existing_tournament.description.present?
            params.delete :description
          elsif params[:description].present?
            params[:description] = params[:description].gsub(/(?:\n\r?|\r\n?)/, '<br>')
          end

          if existing_tournament.logo.present?
            params.delete :logo
          elsif params[:logo].present? && params[:logo]["original"].present?
            params[:logo] = params[:logo]["original"]
          end

          if existing_tournament.full_name.present?
            params.delete :full_name
          end

          if existing_tournament.rules.present?
            params.delete :rules
          end

          params["featured"] = existing_tournament[:featured]
          params = Tournament.convert_time(params)
          if params[:prize].present?
            params[:prize] = params[:prize].gsub(/(?:\n\r?|\r\n?)/, '<br>')
          end

          existing_tournament.update(params)
        else
          params = Tournament.convert_time(params)
          if params[:rules].present?
            params[:rules] = params[:rules].gsub(/(?:\n\r?|\r\n?)/, '<br>')
          end

          if params[:logo].present? && params[:logo]["original"].present?
            params[:logo] = params[:logo]["original"]
          end

          if params[:prize].present?
            params[:prize] = params[:prize].gsub(/(?:\n\r?|\r\n?)/, '<br>')
          end

          if params[:description].present?
            params[:description] = params[:description].gsub(/(?:\n\r?|\r\n?)/, '<br>')
          end
          
          new_tournament = Tournament.new(params)
          new_tournament.save
        end
      rescue Exception => ex
        puts ex
      end
    end
  end

  # Update Match data
  def match_check_tournament(toornament)
    begin
      params = toornament.symbolize_keys
      params[:toornament_id] = params.delete :id
      existing_tournament = Tournament.find_by(toornament_id: params[:toornament_id])
      # if existing_tournament.present? && existing_tournament[:visible] == true
      # end
      save_match(existing_tournament)
    rescue Exception => ex
      puts ex
    end
  end

  def save_match(tournament)
    matches = TournamentApi::DownUploadTournament.new.get_matches tournament.toornament_id
    begin
      if matches.present?
        matches.each do |match_value|
          params = match_value.symbolize_keys
          params[:toornament_match_id] = params.delete :id
          params[:match_type] = params.delete :type
          new_opponents = params[:opponents]
          existing_match = Match.find_by(toornament_match_id: params[:toornament_match_id])
          if existing_match.present?
            opponents = existing_match["opponents"]
            is_next_match = check_next_match(new_opponents)
            if params[:status] == 'pending' && is_next_match == true && existing_match.found_match == false
              # existing_match.found_match = true
              # existing_match.save!
              if Tournament.next_match_players(existing_match).present?
                ActionCable.server.broadcast "room_channel_#{tournament.id}", message: { action: "match_ready", players: Tournament.next_match_players(existing_match), url: "/tournaments/#{tournament.id}/checkin" }
              end
            end
            
            opponents.each_with_index do |o, index|
              if o['result'] != new_opponents[index]["result"]
                ActionCable.server.broadcast "room_channel_#{existing_match.id}", message: { action: "Match data is updated", url: "/tournaments/#{tournament.id}/match/#{existing_match.id}"}
              elsif o['score'] != new_opponents[index]["score"]
                ActionCable.server.broadcast "room_channel_#{existing_match.id}", message: { action: "Match data is updated", url: "/tournaments/#{tournament.id}/match/#{existing_match.id}"}
              elsif o['forfeit'] != new_opponents[index]["forfeit"]
                ActionCable.server.broadcast "room_channel_#{existing_match.id}", message: { action: "Match data is updated", url: "/tournaments/#{tournament.id}/match/#{existing_match.id}"}
              elsif opponents != new_opponents
                ActionCable.server.broadcast "room_channel_#{existing_match.id}", message: { action: "Match data is updated", url: "/tournaments/#{tournament.id}/match/#{existing_match.id}"}
              end
            end
          else
            opponents = params[:opponents]
            full_participant = is_full_participant(opponents)
            if full_participant == true
              ActionCable.server.broadcast "room_channel_#{tournament.id}", message: { action: "Match data is updated", url: "/tournaments/#{tournament.id}/checkin" }
            end
          end
        end
      end
    rescue Exception => ex
      puts ex
    end
  end

  def is_full_participant(opponents)
    full_participant = true
    if opponents.present?
      opponents.each do |o|
        if o["participant"].blank?
          full_participant = false
        end
      end
    else
      full_participant = false
    end
    full_participant
  end

  def check_next_match(opponents)
    is_next_match = true
    if opponents.present?
      opponents.each do |o|
        if o['participant'].present?
          if o['participant']['custom_user_identifier'].blank?
            is_next_match = false
          end
        else
          is_next_match = false
        end
      end
    end
    is_next_match
  end

  # Update the standing
  def standing_check_tournament(toornament)
    begin
      params = toornament.symbolize_keys
      if params[:status] == "completed"
        params[:toornament_id] = params.delete :id
        existing_tournament = Tournament.find_by(toornament_id: params[:toornament_id])
        # if existing_tournament.present? && existing_tournament[:visible] == true
        # end
        save_standing(existing_tournament)
      end
    rescue Exception => ex
      puts ex
    end
  end

  def save_standing(tournament)
    standings = TournamentApi::DownUploadTournament.new.get_standings tournament.toornament_id
    begin
      if standings.present?
        standings.each do |standing_value|
          params = standing_value.symbolize_keys
          params[:toornament_standing_id] = params.delete :id
          existing_standing = Standing.find_by(toornament_standing_id: params[:toornament_standing_id])
          if existing_standing.blank?
            Standing.get_standings(tournament)
            ActionCable.server.broadcast "room_channel_#{tournament.id}", message: { action: "Standing data is updated" }
            break
          elsif existing_standing.ptc_id != new_ptc_id(params) || params[:rank] != existing_standing[:rank]
            Standing.get_standings(tournament)
            ActionCable.server.broadcast "room_channel_#{tournament.id}", message: { action: "Standing data is updated" }
            break
          end
        end
      end
    rescue Exception => ex
      puts ex
    end
  end

  def new_ptc_id(params)
    params[:participant]['custom_user_identifier'].split(':').last.to_i
  end


  # Update stage data
  def stage_check_tournament(toornament)
    begin
      params = toornament.symbolize_keys
      if params[:status] != "completed"
        params[:toornament_id] = params.delete :id
        existing_tournament = Tournament.find_by(toornament_id: params[:toornament_id])
        # if existing_tournament.present? && existing_tournament[:visible] == true
        # end
        save_stage(existing_tournament)
      end
    rescue Exception => ex
      puts ex
    end
  end

  def save_stage(tournament)
    stages = TournamentApi::DownUploadTournament.new.get_stages tournament.toornament_id
    begin
      if stages.present?
        stages.each do |stage, index|
          params = stage.symbolize_keys
          params[:toornament_stage_id] = params.delete :id
          new_settings = params[:settings]
          existing_stage = Stage.find_by(toornament_stage_id: params[:toornament_stage_id])
          if existing_stage.present?
            settings = existing_stage["settings"]
            if settings["size"] != new_settings["size"]
              ActionCable.server.broadcast "room_channel_#{tournament.id}", message: { action: "Stage data is updated" }
              break
            end
          end
        end
      end
    rescue Exception => ex
      puts ex
    end
  end
  
  # Delete the all of data
  task delete: :environment do
    Stage.destroy_all
    Group.destroy_all
    Round.destroy_all
    Match.destroy_all
    Standing.destroy_all
    Participant.destroy_all
    Tournament.destroy_all
  end
end
