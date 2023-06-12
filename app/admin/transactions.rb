ActiveAdmin.register Transaction do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :user_id, :amount, :paypal_id, :transaction_type, :paypal_order_id, :transaction_source, :tournament_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:user_id, :amount, :paypal_id, :transaction_type, :paypal_order_id, :transaction_source, :tournament_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  # autocomplete :user_id, on: [:email, :username]

  form do |f|
    f.inputs do
      f.input :user_id, :as => :select, :collection => User.all.map{|u| ["#{u.email}", u.id]}
      f.input :amount
      f.input :paypal_id
      f.input :transaction_type
      f.input :paypal_order_id
      f.input :transaction_source
      f.input :tournament_id
    end
    actions
  end
  
end
