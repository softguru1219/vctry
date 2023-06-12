ActiveAdmin.register Raffle do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :banner, :sponsor_banner, :title, :description, :youtube, :raffle_url, :cost, :raffle_start_date, :raffle_end_date, 
  :twitter, :facebook, :reddit, :google, :vk, :twitch, :sponsor_name, :prizes
  #
  # or
  #
  # permit_params do
  #   permitted = [:banner, :title, :description, :youtube, :raffle_url, :cost, :raffle_start_date, :raffle_end_date]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
  index do  
    Raffle.column_names.each do |c| 
      column c  
    end 
    actions defaults: true do |raffle|  
      "<a href='javascript:void(0)' class='generate_winner_link' id='#{raffle.id}'>#{I18n.t('raffles.titles.generate_winner')}</a>".html_safe 
    end 
  end 

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :banner
      f.input :sponsor_banner
      f.input :sponsor_name
      f.input :title
      f.input :youtube
      f.input :raffle_url
      f.input :cost
      f.input :raffle_start_date, as: :date_time_picker, label: "Raffle start date (Time has to be in UTC)"
      f.input :raffle_end_date, as: :date_time_picker, label: "Raffle end date (Time has to be in UTC)"
      f.input :twitter
      f.input :facebook
      f.input :reddit
      f.input :google
      f.input :vk
      f.input :twitch
    end
    f.input :description, as: :ckeditor
    f.input :prizes, as: :ckeditor
    actions
  end

  controller do
    def update
      @youtube = params[:raffle][:youtube]
      if @youtube.present? && @youtube.exclude?('/embed/')
        flash[:error] = I18n.t('flash.titles.admin_youtube_alert')
        redirect_to edit_admin_raffle_path(params[:id])
      else
        super
      end
    end

    def create
      @youtube = params[:raffle][:youtube]
      if @youtube.present? && @youtube.exclude?('/embed/')
        flash[:error] = I18n.t('flash.titles.admin_youtube_alert')
        redirect_to new_admin_raffle_path
      else
        super
      end
    end
  end
end
