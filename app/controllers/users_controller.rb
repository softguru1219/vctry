class UsersController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, 
  :only => [:subscribe, :transaction_deposit, :transaction_withdraw, :transaction_buyIn,
    :transaction_vourcher, :renew_cancel, :raffle_ticket, :add_friend, :transaction_refund]
  
  def index
    @users = User.all
  end

  def show
    @tournaments = nil
    if params[:id] != "password"
      @user = User.find(params[:id])
      if @user.present?
        @tournaments = @user.tournaments.where(:featured=>true).where(visible: true)
      end
    else
      redirect_to root_path
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to(:action => 'index')
  end

  def photo_upload
    @user = User.find(params[:id])
    @skip_footer = true
  end

  def notifications
    @is_desktop = is_desktop
    notifications = current_user.notifications
    # current_user.add_notification(icon, url, message)
  end

  def delete_notification
    current_user.notifications.destroy_all
    redirect_to notifications_users_path(current_user)
  end

  def raffles
    @users = User.all
    @raffles = nil
  end

  def subscribe
    begin
      if params['purchase'] == 'onetime'
        if params[:orderID].present?
          response = Paypal::PaypalApi.new.validation_order params[:orderID]
          if response.status == 200
            resp = current_user.subscribe_to(params)
            render json: { status: :ok, data: I18n.t('alert.titles.success_premium')}
          else
            render json: { status: :failed, data: response.body.to_s }
          end
        elsif params[:wallet_pay].present?
          current_user.subscribe_to(params)
          current_user.transaction_to(params, current_user, params[:status])
          render json: {status: :ok, data: I18n.t('alert.titles.success_premium')}
        else
          render json: { status: :failed, data: I18n.t('alert.titles.non_orderId')}
        end
      elsif params[:wallet_pay].present?
        current_user.subscribe_to(params)
        current_user.transaction_to(params, current_user, params[:status])
        render json: { status: :ok, data: I18n.t('alert.titles.success_premium') }
      else
        current_user.subscribe_to(params)
        render json: { status: :ok, data: I18n.t('alert.titles.success_premium') }
      end
    rescue Exception => exception
      Raven.capture_exception(exception)
    end
  end

  def renew_cancel
    if params[:paypal_id].present?
      response = Paypal::PaypalApi.new.cancel_subscription params[:paypal_id]
      if response.status  == 204
        current_user.renew_cancel(params)
        render json: { status: :ok, data: I18n.t('alert.titles.cancel_renewal') }
      end
    end
  end

  def transaction_buyIn
    current_user.transaction_to(params, current_user, 'buyIn')
    render json: { status: :ok }
  end

  def transaction_refund
    current_user.transaction_refund(params, current_user, 'refund')
    @tournament = Tournament.find(params[:tournament_id])
    Participant.delete_participants(@tournament, current_user)
    render json: { status: :ok }
  end

  def transaction_vourcher
    begin
      if params[:orderID].present?
        response = Paypal::PaypalApi.new.validation_order params[:orderID]
        if response.status == 200
          resp = current_user.voucher_to(params)
          CouponMailer.coupon_mail(current_user, resp, params[:interval]).deliver!
          render json: {status: :ok, data: I18n.t('alert.titles.success_voucher_email')}
        else
          render json: { status: :failed, data: response.body.to_s }
        end
      elsif params[:wallet_pay].present?
        resp = current_user.voucher_to(params)
        CouponMailer.coupon_mail(current_user, resp, params[:interval]).deliver!
        current_user.transaction_to(params, current_user, params[:status])
        render json: {status: :ok, data: I18n.t('alert.titles.success_voucher_email')}
      else
        render json: { status: :failed, data: I18n.t('alert.titles.non_orderId')}
      end
    rescue Exception => exception
      Raven.capture_exception(exception)
    end
  end

  def active_creator
    current_user.current_creator_code(params) == true
      # flash[:content_support] = "Thank your for supporting #{ContentCreator.current_creator_code(params).name}"
    # end
    redirect_to get_premium_path
  end

  def promotion
    if Coupon.current_coupon(params).present?
      current_user.subscribe_to(params)
      flash[:coupon] = I18n.t('flash.titles.coupon', :redeem_interval=>Coupon.redeemed_interval(params))
      Coupon.current_coupon(params).delete
    else
      flash[:premium_alert] = I18n.t('flash.titles.premium_alert')
    end
    redirect_to get_premium_path
  end

  def friends
    friends = current_user.friends
  end

  def friend_search
    @search_results = current_user.friend_search(params)
    respond_to do |format|
      format.html {render @search_results}
      format.js 
    end
  end

  def add_friend
    unless current_user.exist_request(params[:id]).present?
      @friend = Friend.new
      @friend.user_a_id = current_user.id
      @friend.user_b_id = params[:id]

      # @notification = Notification.new
      # @notification.user_id = params[:id]
      # @notification.requested_user = current_user.id

      @friend.save!
      @notification.save!
      render json: { status: :ok }
    end
  end

  def confirm_friend
    @friend = Friend.where(user_a_id: params[:id]).where(user_b_id: current_user.id).first
    @friend.confirmed = true
    @friend.save!
    redirect_to friends_users_path(current_user)
  end

  def remove_friend
    @friend = Friend.where(user_a_id: current_user.id).where(user_b_id: params[:id])
    unless @friend.present? 
      @friend = Friend.where(user_a_id: params[:id]).where(user_b_id: current_user.id)
    end

    if @friend.present?
      @friend.first.delete
    end
    redirect_to friends_users_path(current_user)
  end

  def raffle_ticket
    if current_user.subscriptions.present?
      current_user.tickets = current_user.tickets.to_i + 5
    else
      current_user.tickets = current_user.tickets.to_i + 1
    end

    if current_user.last_ticket_claimed.present?
      if (current_user.last_ticket_claimed.to_date + 1.day) > Time.now.utc.to_date
        render json: { status: :failed }
      else
        current_user.last_ticket_claimed = Time.now.utc
        current_user.save!
        render json: { status: :ok, tickets: current_user.tickets }
      end
    else
      current_user.last_ticket_claimed = Time.now.utc
      current_user.save!
      render json: { status: :ok, tickets: current_user.tickets }
    end
  end
end