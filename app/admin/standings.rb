ActiveAdmin.register Standing do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :tournament_id, :rank, :position, :ptc_id, :tooranment_standing_id
  #
  # or
  #
  permit_params do
    permitted = [:tournament_id, :rank, :position, :ptc_id, :tooranment_standing_id]
    permitted << :other if params[:action] == 'create' && current_user.admin?
    permitted
  end
  
end
