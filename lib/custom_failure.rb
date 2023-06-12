class CustomFailure < Devise::FailureApp
  def respond
    if http_auth?
      http_auth
    else
      if params[:desktop].present?
        flash[:alert] = i18n_message
        redirect_to root_path
      else
        redirect
      end
    end
  end
end