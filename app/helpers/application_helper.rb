module ApplicationHelper
  def users
    User.all[0..2]
  end

  def requires_confirm(session, flash)
    result = false
    @user = User.find_by(email: session[:email])
    if @user.present?
      alert = flash[:alert]
      if @user.confirmed_at.blank? && alert.include?(I18n.t('alert.titles.confirm_email_alert'))
        result = true
      end
    end
    result
  end

  def friends
    friends = current_user.friends(true)
  end

  def notifications
    notifications = Notification.all
  end

  def current_time(timezone)
    if timezone.present?
      tz = TZInfo::Timezone.get(timezone)
      current_time = Time.now.getlocal(tz.current_period.offset.utc_total_offset)
    else
      current_time = Time.now
    end
    current_time
  end

  def current_date
    Time.now.utc
  end

  def today
    Time.now.utc.strftime("%Y-%m-%d")
  end

  def schedule_time(schedule_date, timezone)
    if timezone.present?
      tz = TZInfo::Timezone.get(timezone)
      current_time = schedule_date.to_time.getlocal(tz.current_period.offset.utc_total_offset)
      current_time.to_date
    else
      schedule_date
    end
  end

  def ongoing_tournament(tournament)
    is_ongoing = false
    scheduled_date_start = tournament[:registration_opening_datetime]
    scheduled_date_end = tournament[:registration_closing_datetime]
    # if scheduled_date_start.present? && scheduled_date_end.present?
    #   if scheduled_date_start < current_date && scheduled_date_end > current_date
    #     is_ongoing = true
    #   end
    # end
    if scheduled_date_end.present?
      if scheduled_date_end < current_date && tournament[:status].downcase != 'completed'
        is_ongoing = true
      end
    end
    is_ongoing
  end

  def upcoming_tournament(tournament)
    is_upcoming = false
    scheduled_date_start = tournament[:registration_opening_datetime]
    scheduled_date_end = tournament[:registration_closing_datetime]
    if scheduled_date_end.present?
      if scheduled_date_end >= current_date && tournament[:status].downcase != 'completed'
        is_upcoming = true
      end
    end
    is_upcoming
  end

  def upcoming_tournament_list(tournaments)
    results = []
    if tournaments.present?
      tournaments.each do |tournament|
        if upcoming_tournament(tournament) == true
          results << tournament
        end
      end
    end
    results
  end

  def completed_tournament(tournament)
    is_completed = false
    scheduled_date_end = tournament[:registration_closing_datetime]
    # if scheduled_date_end.present?
    #   if scheduled_date_end < current_date
    #     is_completed = true
    #   end
    # end
    if tournament[:status].present?
      if tournament[:status].downcase == 'completed'
        is_completed = true
      end
    end
    is_completed
  end

  def filtered_mine(filtered_tournaments)
    filtered_tournaments.where('id in (?)', current_user.tournaments.pluck(:id).join(',').split(",").map(&:to_i))
  end

  def slots_num(tournament)
    slots = tournament.participants.present? ? tournament.participants.length : 0
    slots
  end

  def open_slotes_num(tournament)
    if tournament[:size].present? && tournament.participants.present?
      (tournament[:size] - tournament.participants.length).abs
    elsif tournament[:size].present?
      (tournament[:size] - 0).abs
    end
  end

  def registration_status(tournament)
    if tournament.registration_closing_datetime.present?
      if tournament[:registration_enabled] == true && Time.now.utc < tournament.registration_closing_datetime
        registration_status = I18n.t('homepage.titles.open').capitalize
      else
        registration_status = I18n.t('homepage.titles.closed').capitalize
      end
    else
      registration_status = I18n.t('homepage.titles.closed').capitalize
    end
  end

  def country(tournament)
    country = '-'
    if tournament.country.present?
      if ISO3166::Country.new(tournament.country).present?
        country = ISO3166::Country.new(tournament.country).local_name
      end
    end
    if country != '-'
      country = "#{country} #{I18n.t('homepage.titles.only').capitalize}"
    end
    country
  end

  def format_date(input_date)
    "#{input_date.strftime("%a, %b")} #{input_date.day.ordinalize}"
  end

  def date_to_string(input_date)
    "#{input_date.strftime("%b %d, %Y")}"
  end


  def stage(tournament)
    matches = tournament.matches
    stage = matches.present? ? matches.first.stage_id : nil
    stage
  end

  def stages(tournament)
    Stage.where(tournament_id: tournament.id)
  end

  def get_plan(plan_name)
    Plan.find_by(:name=>plan_name)
  end

  def current_subscription(current_plan)
    exists_subscription = false
    if current_plan.present? && current_user.subscriptions.where(:plan_id=>current_plan.id, :status=>"active").exists?
      exists_subscription = true
    end
    exists_subscription
  end

  def check_auto_billing(current_plan)
    auto_billing = false
    if current_plan.present? && current_user.subscriptions.where(:plan_id=>current_plan.id, :status=>"active").exists?
      auto_billing = current_user.subscriptions.where(:plan_id=>current_plan.id, :status=>"active").first.auto_bill_outstanding
    end
    auto_billing
  end

  def current_paypal(plan_id)
    @subscription = current_user.subscriptions.find_by(plan_id: plan_id)
    result = @subscription.present? ? @subscription.paypal_subscription_id : nil
    result
  end

  def current_balance
    current_user.transactions.present? ? current_user.transactions.sum(&:amount).round(2) : 0.0
  end

  def current_transactions
    current_user.transactions
  end

  def current_friend(friend)
    if friend[:user_b_id] != current_user.id
      User.find(friend[:user_b_id])
    else
      User.find(friend[:user_a_id])
    end
  end

  def max_premium_expires
    results = []
    current_user.subscriptions.each do |subscription|
      results << subscription.expires_on
    end
    results.max
  end

  def prize(tournament)
    sum_prize = nil
    if tournament.prize.present?
      prize = tournament.prize.split('<br>')
      begin
        sum_prize = prize.inject(0){|sum,x| sum + x.gsub(",", ".").to_f }
        if sum_prize.present?
          sum_prize = number_with_precision(sum_prize.round(2), precision: 2)
        end
        if sum_prize.present? && session[:locale] == "de"
          sum_prize = sum_prize.to_s.gsub(".", ",")
        end
      rescue Exception => exception
        Raven.capture_exception(exception)
      end
    end
    sum_prize
  end

  def prize_list(prize)
    prize.split('<br>')
  end

  def standing_prize(tournament, rank)
    prize = tournament.prize
    single_prize = nil
    if prize.present? and rank.present?
      prize = prize.split('<br>')
      if prize.length >= rank
        single_prize  = prize[rank-1]
      end
    end
    if single_prize.present? 
      if session[:locale] == 'de'
        single_prize = number_with_precision(single_prize, precision: 2).gsub(".", ",")
      else
        single_prize = number_with_precision(single_prize, precision: 2).gsub(",", ".")
      end
    end
    single_prize
  end

  def rules_description(data)
    data.gsub(/(?:\n\r?|\r\n?)/, '<br>').html_safe
    data.html_safe
  end

  def tournament_description(data)
    data.html_safe
  end

  def check_social(selected_table)
    result = false
    if selected_table.twitter.present? || selected_table.facebook.present? || selected_table.reddit.present? || selected_table.google.present? || selected_table.vk.present?
      result = true
    end

    result
  end
end
