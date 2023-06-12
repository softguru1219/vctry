ActiveAdmin.register Participant do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :user_id, :tournament_id, :name, :email, :custom_user_identifier, :checked_in, :custom_fields, :partic_id, :toornament_user_id, :checked_in_at, :lineup, :match_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:user_id, :tournament_id, :name, :email, :custom_user_identifier, :checked_in, :custom_fields, :partic_id, :toornament_user_id, :checked_in_at, :lineup, :match_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
