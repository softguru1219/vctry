# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    if is_desktop
      redirect_to root_path
    else
      super
    end
  end

  # POST /resource/sign_in
  def create
    session[:email] = params[:user][:email]
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
  end

  def auth_options
    if params[:desktop].present?
      { scope: resource_name, recall: "home#index" }
    else
      { scope: resource_name, recall: "#{controller_path}#new" }
    end
  end
end
