ActiveAdmin.register ContentCreator do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :name, :subtitle, :description, :code, :logo, :german_description, :german_subtitle
  #
  # or
  #
  # permit_params do
  #   permitted = [:name, :subtitle, :description, :code, :logo]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
