class PartnerMailer < ApplicationMailer
  before_action :add_inline_attachment!
  
  def partner_mail(params)
    @params = params
    @user = params[:user]
    @language = params[:language]

    subject = I18n.t('mail.titles.partner_subject')
    @email = 'partnerships@vctry.gg'
    # @email = 'bf.professive010@gmail.com'
    mail(to: @email, subject: subject)
  end

  private

  def add_inline_attachment!
    attachments.inline['logo.png'] = File.read("#{Rails.root}/app/assets/images/home/email_logo.png")
  end
end
