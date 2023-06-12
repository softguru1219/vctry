class CouponMailer < ApplicationMailer
  # add_template_helper(EmailHelper)
  before_action :add_inline_attachment!
  
  def coupon_mail(user, coupon_codes, interval)
    @user = user
    subject = I18n.t('mail.titles.voucher_subject')
    @coupon_codes = coupon_codes
    if interval == I18n.t('homepage.titles.day')
      @interval = "1 #{I18n.t('homepage.titles.day').capitalize}"
    elsif interval == I18n.t('homepage.titles.week')
      @interval = "7 #{I18n.t('homepage.titles.days').capitalize}"
    elsif interval == I18n.t('homepage.titles.month')
      @interval = "30 #{I18n.t('homepage.titles.days').capitalize}"
    end
    
    mail(to: @user.email, subject: subject) unless @user.email.nil?
  end

  private

  def add_inline_attachment!
    attachments.inline['logo.png'] = File.read("#{Rails.root}/app/assets/images/home/email_logo.png")
  end
end
