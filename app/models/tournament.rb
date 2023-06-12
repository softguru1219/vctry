class Tournament < ApplicationRecord
  has_many :participants
  has_many :matches
  has_many :rounds
  has_many :stages
  has_many :standings
  
  mount_uploader :tournament_cover, TournamentCoverUploader
  mount_uploader :logo, TournamentLogoUploader
  mount_uploader :featured_image, FeaturedImageUploader
  mount_uploader :mobile_cover, MobileTournamentCoverUploader
  mount_uploader :mobile_logo, MobileTournamentLogoUploader


  FINAL_SCORE_TIMEOUT = 15
  FINAL_SCORE_CONFIRM_TIMEOUT = 5

  def self.get_tournaments
    tournament_id = nil
    tournaments = TournamentApi::DownUploadTournament.new.get_tournaments tournament_id
    if tournaments.present?
      tournaments.each do |tournament|
        toornament = TournamentApi::DownUploadTournament.new.get_tournaments tournament.symbolize_keys[:id]
        Tournament.save_tournament toornament
      end
    end
  end

  def self.update_tournaments(tournament, size)
    if tournament.registration_closing_datetime < Time.now.utc
      if tournament.size != size
        TournamentApi::DownUploadTournament.new.update_tournaments(tournament.toornament_id, size)
        tournament.size = size
        tournament.save!
      end
    end
  end

  def self.save_tournament(toornament)
    begin
      params = toornament.symbolize_keys
      params[:toornament_id] = params.delete :id
      params[:timezone] = 'UTC'
      existing_tournament = Tournament.find_by(toornament_id: params[:toornament_id])
      if existing_tournament
        params = Tournament.convert_time(params)
        existing_tournament.update(params)
      else
        params = Tournament.convert_time(params)
        new_tournament = Tournament.new(params)
        new_tournament.save
      end
    rescue Exception => ex
      puts ex
    end
  end

  def self.current_time(timezone)
    if timezone.present?
      tz = TZInfo::Timezone.get(timezone)
      current_time = Time.now.getlocal(tz.current_period.offset.utc_total_offset)
    else
      current_time = Time.now
    end
    current_time
  end

  def self.convert_time(params)
    timezone = 'UTC'
    params[:scheduled_date_start] = params[:scheduled_date_start].present? ? params[:scheduled_date_start].to_date.asctime.in_time_zone(timezone) : nil
    params[:scheduled_date_end] = params[:scheduled_date_end].present? ? params[:scheduled_date_end].to_date.asctime.in_time_zone(timezone) : nil
    params[:check_in_participant_start_datetime] = params[:check_in_participant_start_datetime].present? ? params[:check_in_participant_start_datetime].to_datetime.asctime.in_time_zone(timezone) : nil
    params[:check_in_participant_end_datetime] = params[:check_in_participant_end_datetime].present? ? params[:check_in_participant_end_datetime].to_datetime.asctime.in_time_zone(timezone) : nil
    params[:registration_opening_datetime] = params[:registration_opening_datetime].present? ? params[:registration_opening_datetime].to_datetime.asctime.in_time_zone(timezone) : nil
    params[:registration_closing_datetime] = params[:registration_closing_datetime].present? ? params[:registration_closing_datetime].to_datetime.asctime.in_time_zone(timezone) : nil
    params
  end

  def self.stream_check(tournament, current_user)
    is_stream = true
    stream_alert = nil
    discord_alert = nil
    final_alert = ''

    if current_user.discord_id.blank?
      is_stream = false
      discord_alert = I18n.t('errors.titles.discord_id')
    end

    if tournament.platforms.present?
      pt = tournament.platforms.first.downcase
      if pt.include?('playstation') && tournament.discipline != 'fifa21'
        if current_user.psn_id.blank?
          stream_alert = I18n.t('errors.titles.psn_id')
          is_stream = false
        end
      elsif pt == 'xbox_one'
        if current_user.xbox_live_id.blank?
          stream_alert = I18n.t('errors.titles.xbox_id')
          is_stream = false
        end
      elsif pt == 'pc'
        if tournament.discipline.downcase  == "fortnite"
          if current_user.epic_id.blank?
            stream_alert = I18n.t('errors.titles.epic_id')
            is_stream = false
          end
        elsif current_user.steam_id.blank?
          stream_alert = I18n.t('errors.titles.steam_id')
          is_stream = false
        end
      end
    end
    if discord_alert.present? && stream_alert.present?
      final_alert = I18n.t('flash.titles.discord_stream_alert', :discord_alert=>discord_alert, :stream_alert=>stream_alert)
    elsif discord_alert.present?
      final_alert = I18n.t('flash.titles.discord_alert', :discord_alert=>discord_alert)
    elsif stream_alert.present?
      final_alert = I18n.t('flash.titles.stream_alert', :stream_alert=>stream_alert)
    end

    return is_stream, final_alert
  end

  def self.upcoming_tournament(tournament)
    is_upcoming = false
    scheduled_date_start = tournament[:scheduled_date_start]
    scheduled_date_end = tournament[:scheduled_date_end]
    if scheduled_date_start.present?
      if scheduled_date_start >= Time.now.utc
        is_upcoming = true
      end
    end
    is_upcoming
  end

  def self.match_ids(tournament)
    @matches = tournament.matches.where.not(status: 'completed')
    match_ids = []
    if @matches.present?
      @matches.each do |m|
        match_ids << m.id
      end
    end
    match_ids
  end

  def self.next_match_players(next_match)
    players = []
    opponents = next_match["opponents"]
    if opponents.present?
      opponents.each do |o|
        begin
          if o["participant"].present? && o["participant"]["custom_user_identifier"].present?
            user_id = o["participant"]["custom_user_identifier"].split(":").last.to_i
            players << user_id
          end
        rescue Exception => exception
          Raven.capture_exception(exception)
        end
      end
    end
    players
  end

  def self.active_tournament(current_user, tournament)
    active_tournament = false
    joining_tournaments = nil
    single_play_alert = nil
    able_single_play = false
    joining_tournaments = current_user.tournaments.where(single_play: true).where.not(status: 'completed').where(visible: true)
    begin
      if joining_tournaments.present?
        joining_tournaments.each do |jt|
          current_participants = jt.participants.where(user_id: current_user.id)
          if current_participants.present?
            if current_participants.first.checked_in == true
              able_single_play = true
            elsif jt.check_in_participant_end_datetime > Time.now.utc
              able_single_play = true
            end
          end
          if able_single_play == true
            match_status = Tournament.completed_match_status(jt, current_user)
            if match_status == true
              active_tournament = true
            elsif Tournament.none_completed_match_status(jt, current_user) == true
              active_tournament = true
            end
            if active_tournament == true
              single_play_alert = I18n.t('flash.titles.single_play', :tournament_name=>jt.full_name)
              break
            end
          end
        end
      end
    rescue Exception => exception
      Raven.capture_exception(exception)
    end
    
    return active_tournament, single_play_alert
  end

  def self.completed_match_status(tournament, current_user)
    matches = tournament.matches
    is_next_match = true
    if matches.present?
      matches = matches.where(:status=>"completed")
      matches.each do |m|
        if is_next_match == false
          break
        else
          begin
            opponents = m[:opponents]
            if opponents.present?
              opponents.each do |o|
                if o["participant"].present? && 
                  curstom_user_identifier = o["participant"]["custom_user_identifier"]
                  if current_user.id == curstom_user_identifier.split(":").last.to_i
                    if o["result"] == 'loss' || o['forfeit'] == true
                      is_next_match = false
                      break
                    end
                  end
                end
              end
            end
          rescue Exception => ex
            puts ex
          end
        end
      end
    end
    is_next_match
  end

  def self.none_completed_match_status(tournament, current_user)
    is_next_match = false
    matches = tournament.matches.where.not(status: 'completed')
    if matches.present?
      matches.each do |m|
        if is_next_match == true
          break
        else
          begin
            opponents = m[:opponents]
            opponents.each do |o|
              if o["participant"].present?
                curstom_user_identifier = o["participant"]["custom_user_identifier"]
                if current_user.id == curstom_user_identifier.split(":").last.to_i
                  is_next_match = true
                  break
                end
              end
            end
          rescue Exception => ex
            puts ex
          end
        end
      end
    end
    is_next_match
  end

  def self.step_index(tournament)
    idx = 0
    if tournament.protection == true && tournament.protection_pwd.present?
      idx = 1
    end
    idx
  end

  def self.fee(tournament_price)
    tournament_price * 0.1
  end

  def self.normal_stage(tournament)
    is_normal = true
    if tournament.present? && tournament.stages.present?
      if tournament.stages.first.stage_type == "simple" || tournament.stages.first.stage_type == "ffa_single_elimination" || tournament.stages.first.stage_type == "ffa_bracket_groups"
        is_normal = false
      end
    end
    is_normal
  end
end
