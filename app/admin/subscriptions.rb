ActiveAdmin.register Subscription do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :user_id, :plan_id, :subscription_type, :start_date, :expires_on, :paypal_subscription_id, :status, :price_cents, :price_currency, :period, :description, :frequency, :auto_bill_outstanding, :tournament_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:user_id, :plan_id, :subscription_type, :start_date, :expires_on, :paypal_subscription_id, :status, :price_cents, :price_currency, :period, :description, :frequency, :auto_bill_outstanding, :tournament_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
