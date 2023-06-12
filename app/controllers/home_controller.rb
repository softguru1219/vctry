class HomeController < ApplicationController
  def index
    @tournaments = Tournament.where(visible: true).where(:featured=>true).where.not(:status=>"completed").order("registration_closing_datetime ASC")
    # @tournaments = Tournament.where(visible: true)
  end

  def creator_page
  end

  def partner_request
    PartnerMailer.partner_mail(params).deliver!
    respond_to do |format|
      begin
        format.html  { redirect_to(content_creator_path, 
                      :notice => I18n.t('flash.titles.thanks_requesting'))}

      rescue
        format.html  { redirect_to(content_creator_path, 
                      :partner_request => I18n.t('flash.titles.thanks'))}
      end
    end
  end

  def privacy
    if session[:locale] == 'de'
      redirect_to datenschutz_path
    end
  end

  def legal_notice
    if session[:locale] == 'de'
      redirect_to impressum_path
    end
  end

  def terms
    if session[:locale] == 'de'
      redirect_to agb_path
    end
  end

  def faq
  end

  def datenschutz
  end

  def impressum
  end

  def agb
  end

  def about
    if session[:locale] == 'de'
      redirect_to uber_path
    end
  end

  def uber
    if session[:locale] == 'en'
      redirect_to about_path
    end
  end

  def jobs
    if session[:locale] == 'de'
      redirect_to arb_path
    end
  end

  def arb
    if session[:locale] == 'en'
      redirect_to jobs_path
    end
  end

end
