class User < ApplicationRecord
  # validates :username, uniqueness: true
  validates :email, uniqueness: true
  validates :discord_id, :battle_tag_id, :psn_id, :xbox_live_id, :steam_id, uniqueness: true, :allow_blank => true
  validates_acceptance_of :terms_and_conditions, unless: Proc.new { |u| u.reset_password_token.present? }

  rolify

  mount_uploader :avatar, AvatarUploader
  mount_uploader :cover, CoverUploader

  # after_create :assign_default_role

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  attr_accessor :played_games
  attr_accessor :custom_roles

  enum role: [:user, :tournament_admin, :support_admin, :supervisor_admin, :superadmin, :payment_admin, :master_admin]
  after_initialize :set_default_role, :if => :new_record?
  # validates :username, presence: :true, uniqueness: { case_sensitive: false }
  # validates :email, presence: :true, uniqueness: { case_sensitive: false }

  has_many :participants
  has_many :tournaments, through: :participants
  has_many :subscriptions
  has_many :transactions
  has_many :notifications
  belongs_to :content_creator, optional: true
  has_many :raffle_winners
  
  before_save do
    if self.firstname_changed? || self.lastname_changed?
      self.full_name = "#{self.firstname} #{self.lastname}"
    end
  end

  def full_name
    "#{self.firstname} #{self.lastname}"
  end
  
  def played_games=(value)
    played_games_will_change!
    super(value.split(','))
  end

  # def assign_default_role
  #   self.add_role(:user) if self.roles.blank?
  # end

  def set_default_role
    self.role ||= :user
  end

  def balance
    prng = Random.new
    balance = prng.rand(100)
    balance
  end

  def coupon
    SecureRandom.base58(10)
  end

  def has_subscription?; return subscriptions.count > 0; end;
  def current_plan
    if has_subscription?
      subscriptions.first.plan
    else
      return nil
    end
  end
  
  def renew_cancel(params)
    @renew_subscription = self.subscriptions.find_by(plan_id: params[:current_plan])
    if @renew_subscription.present?
      @renew_subscription.auto_bill_outstanding = false
      @renew_subscription.save!
    end
  end

  def subscribe_to(params)
    @subscription = Subscription.new
    @subscription.plan_id = params[:current_plan]
    @subscription.user_id = self.id
    @subscription.status = Subscription.statuses[:active]
    @subscription.paypal_subscription_id = params[:subscription]
    @subscription.start_date = DateTime.now.utc

    last_expires_date = Subscription.last_expires_date(self)
    if params[:current_plan].present?
      @subscription.period = params[:interval].capitalize if params[:interval].present?
      @subscription.expires_on = Plan.find(params[:current_plan]).end_date_from(last_expires_date)
    elsif params[:promoCode].present?
      @subscription.period = Coupon.current_coupon(params).interval.capitalize if Coupon.current_coupon(params).interval.present?
      @subscription.expires_on = Coupon.current_coupon(params).end_date_from(last_expires_date)
    elsif params[:purchase] == 'onetime'
      @subscription.expires_on = self.end_date_from(last_expires_date, params[:interval])
    end
    @subscription.save!
  end

  def transaction_to(params, current_user, type)
    @transaction = Transaction.new
    @transaction.user_id = current_user.id
    if params[:wallet_pay].present?
      if type == 'premium_withdraw'
        @transaction.transaction_type = Transaction.transaction_types[:premium_withdraw]
        @transaction.amount = -(params[:amount].to_f)
        @transaction.save
      end
    else
      if type == 'deposit'
        @transaction.transaction_type = Transaction.transaction_types[:deposit]
        @transaction.amount = params[:amount]
      elsif type == 'withdraw'
        @transaction.transaction_type = Transaction.transaction_types[:withdraw]
        @transaction.amount = -(params[:amount])
      elsif type == 'buyIn'
        @transaction.transaction_type = Transaction.transaction_types[:buyIn]
        @transaction.amount = -(params[:amount].to_f)
        @transaction.tournament_id = params[:tournament_id]
      end
      @transaction.paypal_id = params[:payerID]
      @transaction.paypal_order_id = params[:orderID]
      @transaction.transaction_source = Transaction.transaction_sources[:paypal]
      @transaction.save!
    end
  end

  def transaction_refund(params, current_user, type)
    @transaction = current_user.transactions.where(transaction_type: "buyIn")
    if @transaction.present?
      @transaction.destroy_all
    end
  end

  def voucher_to(params)
    coupons = []
    (1..params[:quantity].to_i).each do |i|
      @coupon = Coupon.new
      @coupon.coupon_code = self.coupon
      @coupon.creator = self
      @coupon.one_use = true
      @coupon.interval = Plan.intervals[params[:interval]]
      puts @coupon.coupon_code
      @coupon.save!
      coupons << @coupon.coupon_code
    end
    coupons
  end

  def self.schedule_run_expired_subscription_unsubscribe
    @today = Time.now.utc.strftime("%Y-%m-%d")
    @subscription = Subscription.where("expires_on = ? OR expires_on < ?", @today, @today)
    if @subscription.present?
      @subscription.destroy_all
      puts 'Worked crontab for unsubscribe'
    else
      puts 'Does not exist the subscription'
    end
  end

  def self.schedule_run_expired_auto_unsubscribe
    @today = Time.now.utc.strftime("%Y-%m-%d")
    @subscription = Subscription.where(expires_on: @today)
    if @subscription.present?
      @auto_renew_subscription = nil
      @plan = Plan.find_by(:name=>"Monthly plan")
      if @plan.present?
        @auto_renew_subscriptions = Subscription.where(plan_id: @plan.id).where(auto_bill_outstanding: true)
      end
      if @auto_renew_subscriptions.present?
        @auto_renew_subscriptions.each do  |auto_subscription|
          @user = auto_subscription.user
          @subscriptions = @user.subscriptions
          if @subscriptions.present? && (Subscription.last_expires_date(@user) == @today.to_date)
            auto_subscription.expires_on = Plan.find(@plan.id).end_date_from(Subscription.last_expires_date(@user))
            auto_subscription.save!
          end
        end
      end
      puts 'Worked crontab for unsubscribe'
    else
      puts 'Does not exist the subscription'
    end
  end

  def friend_requests
    Friend.where(:user_b_id=>self.id).where(:confirmed=>false)
  end

  def friends(confirmed = nil)
    @friends = Friend.where("user_a_id = ? or user_b_id = ?", self.id, self.id)
    @friends = @friends.where(confirmed: confirmed) unless confirmed.nil?
    return @friends
  end

  def exist_request(requestID)
    Friend.where("user_a_id = ? or user_b_id = ?", requestID, requestID).where(confirmed: false)
  end

  def friend_search(params)
    result = User.where('full_name ILIKE ?', "%#{params[:search]}%").where("id NOT in (?)", [-1, self.friends.pluck(:user_a_id), self.friends.pluck(:user_b_id)].join(',').split(",").map(&:to_i))
    if result.blank?
      result = User.where('username ILIKE ?', "%#{params[:search]}%").where("id NOT in (?)", [-1, self.friends.pluck(:user_a_id), self.friends.pluck(:user_b_id)].join(',').split(",").map(&:to_i))
    end
    
    if result.present?
      result = result.where.not(id: self)
    end
    result
  end

  def self.admin_roles
    ["tournament_admin", "support_admin", "payment_admin", "master_admin"]
  end

  def current_creator_code(params)
    if params[:code].present?
      @content_creator = ContentCreator.current_creator_code(params)
      if @content_creator.present?
        self.content_creator_id = @content_creator.id
        self.save!
      end
    end
  end

  def end_date_from(date = nil, interval)
    date ||= Date.current.to_date
    interval_count ||= 1
    case interval
      when "day"
        return date + interval_count.day
      when "week"
        return date + interval_count.week
      when "month"
        return date + interval_count.month
      when "threemonth"
        return date + 3.month
      when "year"
        return date + interval_count.year
      else
    end
  end

  def _sum_premium_expires
    results = []
    self.subscriptions.each do |subscription|
      results << (Time.now.utc.strftime("%Y-%m-%d").to_date - subscription.expires_on).to_i.abs
    end
    results.inject(0){|sum,x| sum + x }
  end

  def sum_premium_expires
    results = 0
    if self.subscriptions.present?
      last_expires_date = Subscription.last_expires_date(self)
      results = (Time.now.utc.strftime("%Y-%m-%d").to_date - last_expires_date).to_i.abs
    end
    results
  end

  def premium_remain_date
    remain_date = self.sum_premium_expires
    # remain_date = (Time.now.utc.strftime("%Y-%m-%d").to_date - max_premium_expires).to_i.abs
    # if remain_date > 24
    #   "for 24 more days"
    if remain_date < 2
      "#{remain_date} #{I18n.t('homepage.titles.day')}"
    else
      "#{remain_date} #{I18n.t('homepage.titles.days')}"
    end
  end

  def custom_roles= (attributes)
  end
end
