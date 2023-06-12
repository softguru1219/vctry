ActiveAdmin.register User do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :email, :encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at, :role, 
  :username, :firstname, :lastname, :address, :birthday, :country, :payment, :fifa_id, :heathstone_id, :youtube, :twitch_id, 
  :discord_id, :battle_tag_id, :psn_id, :xbox_live_id, :steam_id, :full_name, :content_creator_id, :avatar, :cover, :played_games, 
  :user_message, :tickets, :last_ticket_claimed, :epic_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:email, :encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at, :admin, :subscriber, :tournament_admin, :support_admin, :supervisor_admin, :payment_admin, :master_admin, :role, :username, :firstname, :lastname, :address, :birthday, :country, :payment, :fifa_id, :heathstone_id, :youtube, :twitch_id, :discord_id, :battle_tag_id, :psn_id, :xbox_live_id, :steam_id, :full_name, :content_creator_id, :avatar, :cover, :played_games, :user_message]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
  member_action :login_as, :method => :get do
    user = User.find(params[:id])
    bypass_sign_in user
    redirect_to root_path 
  end

  index do
    User.column_names.each do |c|
      column c
    end

    actions defaults: true do |user|
      link_to 'Login as', login_as_admin_user_path(user)
      if user.confirmed_at.nil?
        link_to('Login as', login_as_admin_user_path(user)) + " " + link_to(I18n.t('user.edit.titles.resend_confirmation'),  user_confirmation_path(user: {:email => user[:email]}), :method => :post)
      else
        link_to('Login as', login_as_admin_user_path(user))
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :email
      f.input :custom_roles, :as => :check_boxes, collection: User.admin_roles.each_with_index.map{|x, idx| [x, idx, {:checked=> user.roles.where(name: x).present? }] }

      # f.input :roles, :collection => Role.global,
      #   :label_method => lambda { |el| t "simple_form.options.user.roles.#{el.name}" }
      f.input :username
      f.input :firstname
      f.input :lastname
      f.input :address
      f.input :birthday
      f.input :country
      f.input :payment
      f.input :fifa_id
      f.input :heathstone_id
      f.input :youtube
      f.input :twitch_id
      f.input :discord_id
      f.input :battle_tag_id
      f.input :psn_id
      f.input :xbox_live_id
      f.input :steam_id
      f.input :epic_id
      f.input :full_name
      f.input :content_creator_id
      f.input :avatar
      f.input :cover
      f.input :played_games
      f.input :user_message
      f.input :tickets
      f.input :last_ticket_claimed, as: :date_time_picker
    end
    actions
  end

  show do
    attributes_table do
      row :email
      row :tournament_admin
      row :username
      row :firstname
      row :lastname
      row :address
      row :birthday
      row :country
      row :payment
      row :fifa_id
      row :heathstone_id
      row :youtube
      row :twitch_id
      row :discord_id
      row :battle_tag_id
      row :psn_id
      row :xbox_live_id
      row :steam_id
      row :epic_id
      row :full_name
      row :content_creator_id
      row :avatar
      row :cover
      row :played_games
      row :user_message
      row :tickets
      row :last_ticket_claimed
      row :balance do |user|
        user.transactions.present? ? "#{user.transactions.sum(&:amount).round(2)}€" : "#{0}€"
      end
      row :premium do |user|
        user.premium_remain_date
      end
    end
    active_admin_comments
  end

  controller do
    def update
      custom_roles = params[:user][:custom_roles]
      @user = User.find_by(email: params[:user][:email])
      if @user.roles.present?
        @user.roles.destroy_all
      end
      if custom_roles.present?
        custom_roles.each do |cr|
          if cr.present?
            @user.add_role(User.admin_roles[cr.to_i])
          end
        end
      end
      super
    end
  end
end
