# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    if is_desktop
      redirect_to root_path
    else
      super
    end
  end

  # POST /resource
  def create
    build_resource(sign_up_params)
    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      response_to_sign_up_failure resource
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :username, :password, :password_confirmation, :terms_and_conditions])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(
      :account_update, keys: 
      [:username, :firstname, :lastname, :address, :birthday, :country, :payment, :fifa_id, 
        :heathstone_id, :youtube, :twitch_id, :discord_id, :battle_tag_id, :psn_id, :xbox_live_id, 
        :steam_id, :full_name, :played_games, :terms_and_conditions, :cover, :avatar, :epic_id
      ]
    )
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    stored_location_for(resource) || edit_users_path
  end

  # The path used after sign up for inactive accounts.
  def after_update_path_for(resource)
    stored_location_for(resource) || user_path(current_user)
  end

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def response_to_sign_up_failure(resource)
    email_alert = I18n.t('alert.titles.email_alert')
    username_alert = I18n.t('alert.titles.username_alert')
    # if User.pluck(:username).include? resource.username
    #   flash[:signup_alert] = username_alert
    #   if params[:desktop].present?
    #     redirect_to root_path
    #   else
    #     redirect_to new_user_registration_path
    #   end
    if User.pluck(:email).include? resource.email
      flash[:signup_alert] = email_alert
      if params[:desktop].present?
        redirect_to root_path
      else
        redirect_to new_user_registration_path
      end
    elsif resource.terms_and_conditions == false
      flash[:signup_alert] = I18n.t('alert.titles.terms_alert')
      if params[:desktop].present?
        redirect_to root_path
      else
        redirect_to new_user_registration_path
      end
    end
  end
end
