ActiveAdmin.register Match do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :tournament_id, :scheduled_datetime, :public_note, :private_note, :toornament_match_id, :status, :group_id, :stage_id, :round_id, :number, :match_type, :settings, :played_at, :report_closed, :opponents, :checked_in, :scores, :submitter_id, :confirmer_id, :host_id, :found_match
  json_editor
  #
  # or
  #
  # permit_params do
  #   permitted = [:tournament_id, :scheduled_datetime, :public_note, :private_note, :toornament_match_id, :status, :group_id, :stage_id, :round_id, :number, :match_type, :settings, :played_at, :report_closed, :opponents, :checked_in, :scores, :submitter_id, :confirmer_id, :host_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
