ActiveAdmin.register AdminUser do
  # permit_params :email, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :current_sign_in_at
    column :sign_in_count
    column :created_at

    # column :roles do |user|
    #   user.roles.collect {|c| c.name.capitalize }.to_sentence
    # end
    actions
  end

  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  form do |f|
    f.inputs do
      f.input :email
      f.input :password
      f.input :password_confirmation
      
      f.input :roles, :collection => Role.global,
        :label_method => lambda { |el| t "simple_form.options.user.roles.#{el.name}" }
    end
    f.actions
  end

  controller do
    def update
      params[:user].each{|k,v| resource.send("#{k}=",v)}
      super
    end

    def permitted_params
      params.permit user: [ :email, :password, :password_confirmation, :role_ids]
    end
  end

end
