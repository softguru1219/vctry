# frozen_string_literal: true

if defined?(ActionMailer)
  class Devise::Mailer < Devise.parent_mailer.constantize
    include Devise::Mailers::Helpers
    before_action :add_inline_attachment!

    layout 'mailer'

    def confirmation_instructions(record, token, opts = {})
      @token = token
      devise_mail(record, :confirmation_instructions, opts)
    end

    def reset_password_instructions(record, token, opts = {})
      @token = token
      devise_mail(record, :reset_password_instructions, opts)
    end

    def unlock_instructions(record, token, opts = {})
      @token = token
      devise_mail(record, :unlock_instructions, opts)
    end

    def email_changed(record, opts = {})
      devise_mail(record, :email_changed, opts)
    end

    def password_change(record, opts = {})
      devise_mail(record, :password_change, opts)
    end

    private

    def add_inline_attachment!
      attachments.inline['logo.png'] = File.read("#{Rails.root}/app/assets/images/home/email_logo.png")
    end
  end
end
