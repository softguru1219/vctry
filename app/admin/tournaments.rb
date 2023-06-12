ActiveAdmin.register Tournament do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :name, :full_name, :timezone, :public, :size, :online, :location, :country, :registration_enabled, :registration_opening_datetime, 
  :registration_closing_datetime, :toornament_id, :discipline, :status, :platforms, :contact, :discord, :website, :description, :rules, :match_report_enabled, 
  :registration_request_message, :check_in_enabled, :check_in_participant_enabled, :check_in_participant_start_datetime, :check_in_participant_end_datetime, 
  :archived, :registration_acceptance_message, :registration_refusal_message, :registration_terms_enabled, :registration_terms_url, :participant_type, 
  :team_min_size, :team_max_size, :organization, :logo, :featured, :registration_notification_enabled, :premium, :cost, :scheduled_date_start, :scheduled_date_end, 
  :price, :prize, :tournament_cover, :youtube, :twitter, :facebook, :reddit, :google, :vk, :instagram, :last_queried, :featured_image, :single_play, :visible, :mobile_cover, :mobile_logo
  # :protection, :protection_pwd
  json_editor
  # or
  #
  # permit_params do
  #   permitted = [:name, :full_name, :timezone, :public, :size, :online, :location, :country, :registration_enabled, :registration_opening_datetime, :registration_closing_datetime, :toornament_id, :discipline, :status, :platforms, :contact, :discord, :website, :description, :rules, :match_report_enabled, :registration_request_message, :check_in_enabled, :check_in_participant_enabled, :check_in_participant_start_datetime, :check_in_participant_end_datetime, :archived, :registration_acceptance_message, :registration_refusal_message, :registration_terms_enabled, :registration_terms_url, :participant_type, :team_min_size, :team_max_size, :organization, :logo, :featured, :registration_notification_enabled, :premium, :cost, :scheduled_date_start, :scheduled_date_end, :price, :prize]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end


  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :visible
      f.input :name
      f.input :full_name
      f.input :timezone
      f.input :public
      f.input :size
      f.input :online
      f.input :location
      # f.input :country
      f.input :registration_enabled
      f.input :registration_opening_datetime
      f.input :registration_closing_datetime
      f.input :discipline
      f.input :status
      f.input :platforms
      f.input :contact
      f.input :discord
      f.input :website
      f.input :match_report_enabled
      f.input :registration_request_message
      f.input :check_in_enabled
      f.input :check_in_participant_enabled
      f.input :check_in_participant_start_datetime
      f.input :check_in_participant_end_datetime
      f.input :archived
      f.input :registration_acceptance_message
      f.input :registration_refusal_message
      f.input :registration_terms_enabled
      f.input :registration_terms_url
      f.input :participant_type
      f.input :team_min_size
      f.input :team_max_size
      f.input :organization
      f.input :logo
      f.input :mobile_logo
      f.input :featured
      f.input :featured_image
      f.input :registration_notification_enabled
      f.input :premium
      # f.input :cost
      f.input :scheduled_date_start
      f.input :scheduled_date_end
      f.input :price
      f.input :prize
      f.input :tournament_cover
      f.input :mobile_cover
      f.input :youtube
      f.input :twitter
      f.input :facebook
      f.input :reddit
      f.input :google
      f.input :vk
      f.input :instagram
      f.input :last_queried
      f.input :single_play
      # f.input :protection, label: "Password protected"
      # f.input :protection_pwd, label: "Password"
    end
    f.input :rules, as: :ckeditor
    f.input :description, as: :ckeditor
    actions
  end

  index do
    Tournament.column_names.each do |c|
      if c.to_sym != :description && c.to_sym != :rules
        column c 
      end
    end
    actions
  end
  # controller do
  #   def update
  #     @description = params[:tournament][:description]
  #     begin
  #       toornament_id = Tournament.find(params[:id]).toornament_id
  #       TournamentApi::DownUploadTournament.new.update_tournament_description(toornament_id, @description)
  #     rescue Exception => ex
  #       puts ex
  #     end
  #     redirect_to admin_tournament_path(params[:id])
  #   end
  # end
  
end
