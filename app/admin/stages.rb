ActiveAdmin.register Stage do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :tournament_id, :toornament_stage_id, :number, :name, :stage_type, :closed, :settings
  #
  # or
  #
  # permit_params do
  #   permitted = [:tournament_id, :toornament_stage_id, :number, :name, :stage_type, :closed, :settings]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
