module TournamentsHelper

  def is_player(matches)
    is_player = false
    begin
      opponents = matches[:opponents]
      if opponents.present?
        opponents.each do |o|
          curstom_user_identifier = o["participant"]["custom_user_identifier"]
          if current_user.id == curstom_user_identifier.split(":").last.to_i
            is_player = true
            break
          end
        end
      end
    rescue Exception => ex
      puts ex
    end
    is_player
  end

  def check_forfeit(matches)
    forfeit = true
    begin
      opponents = matches[:opponents]
      if opponents.present?
        opponents.each do |o|
          forfeit = o["forfeit"]
        end
      end
    rescue Exception => ex
      puts ex
    end
    forfeit
  end

  def status_check_in(matches)
    status = false
    begin
      opponents = matches[:opponents]
      if opponents.present?
        opponents.each do |o|
          curstom_user_identifier = o["participant"]["custom_user_identifier"]
          if current_user.id == curstom_user_identifier.split(":").last.to_i
            if matches[:checked_in].present? && matches[:checked_in][current_user.id.to_s].present?
              if matches[:checked_in][current_user.id.to_s] == true
                status = matches[:checked_in][current_user.id.to_s]
                break
              end
            end
          end
        end
      end
    rescue Exception => ex
      puts ex
    end
    status
  end

  def match_type(matches)
    matches.status
  end

  def match_schedule_time(matches, tournament)
    matches.scheduled_datetime
  end

  def match_check_time(tournament)
    if tournament.check_in_participant_end_datetime.present?
      # schedule_time = (matches.scheduled_datetime - 10.minutes)
      schedule_time = tournament.check_in_participant_end_datetime + 20.minutes
    else
      schedule_time = Time.now.utc
    end
    schedule_time
  end
  
  def get_players(matches)
    full_names = []
    begin
      opponents = matches[:opponents]
      if opponents.present?
        opponents.each do |o|
          curstom_user_identifier = o["participant"]["custom_user_identifier"]
          user_id = curstom_user_identifier.split(":").last.to_i
          full_names << "#{User.find_by(id: user_id).firstname} #{User.find_by(id: user_id).lastname}"
        end
      end
    rescue Exception => ex
      puts ex
    end
    full_names
  end

  def fifa_players(matches)
    players = []
    begin
      opponents = matches[:opponents]
      if opponents.present?
        opponents.each do |o|
          curstom_user_identifier = o["participant"]["custom_user_identifier"]
          user_id = curstom_user_identifier.split(":").last.to_i
          players << User.find(user_id).username
        end
      end
    rescue Exception => ex
      puts ex
    end
    players
  end

  def score_players(matches)
    players = []
    begin
      opponents = matches[:opponents]
      if opponents.present?
        opponents.each do |o|
          curstom_user_identifier = o["participant"]["custom_user_identifier"]
          user_id = curstom_user_identifier.split(":").last.to_i
          players << user_id
        end
      end
    rescue Exception => ex
      puts ex
    end
    players
  end

  def score(current_match)
    scores = [0, 0]
    begin
      if current_match.scores.present?
        first_score = current_match.scores[score_players(current_match).first.to_s]
        second_score = current_match.scores[score_players(current_match).second.to_s]
        scores = [first_score, second_score]
      end
    rescue Exception => ex
      puts ex
    end
    scores
  end

  def confirm_user(matches)
    confirm_user = nil
    opponents = matches[:opponents]
    opponents.each do |o|
      curstom_user_identifier = o["participant"]["custom_user_identifier"]
      user_id = curstom_user_identifier.split(":").last.to_i
      if current_user.id != user_id
        # confirm_user = o["participant"]["name"]
        confirm_user = User.find(user_id).username
      end
    end
    confirm_user
  end

  def finished_time(matches)
    played_at = matches[:played_at]
    scheduled_datetime = matches[:scheduled_datetime]
    finished_time = played_at.present? && scheduled_datetime.present? ? TimeDifference.between(scheduled_datetime, played_at).in_general : nil
    finished_time
  end

  def active_player(player, matches, idx)
    active_player = nil
    opponents = matches[:opponents]
    o = opponents[idx]
    if o["participant"].present? && o["participant"]["custom_user_identifier"].present?
      curstom_user_identifier = o["participant"]["custom_user_identifier"]
      user_id = curstom_user_identifier.split(":").last.to_i
      username = User.find(user_id).username
      if username == player 
        active_player = User.find(user_id)
      end
    end
    active_player
  end

  def ready_status(active_player, matches)
    status = false
    if matches[:checked_in].present? && active_player.present?
      if matches[:checked_in][active_player.id.to_s] == true
        status = true
      end
    end
    status
  end

  def another_player(matches)
    another_player = nil
    begin
      opponents = matches[:opponents]
      if opponents.present?
        opponents.each do |o|
          curstom_user_identifier = o["participant"]["custom_user_identifier"]
          if current_user.id != curstom_user_identifier.split(":").last.to_i
            another_player = o["participant"]["name"]
            break
          end
        end
      end
    rescue Exception => ex
      puts ex
    end
    another_player
  end

  def paid_tournament(tournament)
    paid_tournament = false 
    if current_user.transactions.find_by(tournament_id: tournament.id, transaction_type: Transaction.transaction_types[:buyIn]).present?
      paid_tournament = true
    end
    paid_tournament
  end

  def game_style(tournament)
    tournament[:discipline].present? ? tournament[:discipline].gsub('_', ' ') : ''
  end

  def get_fifa(matches, tournament)
    title = platform_id(tournament)
    fifa_ids = []
    begin
      if title.present?
        opponents = matches[:opponents]
        if opponents.present?
          opponents.each do |o|
            curstom_user_identifier = o["participant"]["custom_user_identifier"]
            user_id = curstom_user_identifier.split(":").last.to_i
            if title == I18n.t('errors.titles.psn_id')
              if User.find_by(id: user_id).psn_id.present?
                fifa_ids << User.find_by(id: user_id).psn_id
              end
            elsif title == I18n.t('errors.titles.xbox_id')
              if User.find_by(id: user_id).xbox_live_id.present?
                fifa_ids << User.find_by(id: user_id).xbox_live_id
              end
            elsif title == I18n.t('errors.titles.steam_id')
              if User.find_by(id: user_id).steam_id.present?
                fifa_ids << User.find_by(id: user_id).steam_id
              end
            end
          end
        end
      end
    rescue Exception => ex
      puts ex
    end
    fifa_ids
  end

  def platform_id(tournament)
    pf = platform(tournament)
    title = nil
    if pf.present?
      if pf.include?('playstation')
        title = I18n.t('errors.titles.psn_id')
      elsif pf == 'xbox_one'
        title = I18n.t('errors.titles.xbox_id')
      elsif pf == 'pc'
        title = I18n.t('errors.titles.steam_id')
      end
      # else
      #   title = pf.upcase.gsub('_', ' ')
      # end
    end
    title
  end
  
  def platform(tournament)
    tournament.platforms.present? ? tournament.platforms.first.downcase : nil
  end

  def waiting_list(tournament)
    result = nil
    if tournament[:size].present? && tournament.participants.present?
      slots_num = tournament.participants.length
      if slots_num > tournament[:size]
        result = slots_num - tournament[:size]
      end
    end
    result
  end

  def round_schedule_time(round)
    result = nil
    round_time = Match.where(round_id: round.toornament_round_id)
                      .where(group_id: round.round_group_id)
                      .where(stage_id: round.round_stage_id)
                      .where('scheduled_datetime IS NOT NULL')
    if round_time.present?
      result = local_time(round_time.first.scheduled_datetime, format: "%H:%M %p %Z")
    end
    result
  end

  def condition_join_tournament(tournament)
    status = true
    if tournament.premium == true && !current_user.subscriptions.present?
      status = false
    end
    if tournament.price > 0 && paid_tournament(tournament) == false
      status = false
    end
    status
  end

  def next_match_status(tournament)
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
                if o["participant"].present?
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

  def match_stage_number(current_match)
    stage_number = nil
    if current_match.present?
      match_number = current_match.number
      round_id = current_match.round_id
      round_number = Round.find_by(toornament_round_id: round_id).number
      if round_number.present? && match_number.present?
        stage_number = "#{I18n.t('homepage.titles.round').capitalize} #{round_number} > #{I18n.t('homepage.titles.match').capitalize} #{match_number}"
      end
    end
    stage_number
  end

  def partnerInfo(players)
    result = nil
    begin
      if players.present?
        players.delete_at(players.index(current_user.id))
        result = players.present? ? User.find(players.first).discord_id : nil
      end
    rescue Exception=>ex
      print ex
    end
    result
  end

  def single_stage(tournament)
    single_stage = true
    if tournament.stages.present?
      if tournament.stages.first.stage_type != "single_elimination"
        single_stage = false
      end
    end
    single_stage
  end
end