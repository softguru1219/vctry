module UsersHelper
  def current_age(birthday)
    if birthday.present?
      now = Time.now.utc.to_date
      now.year - birthday.year - ((now.month > birthday.month || (now.month == birthday.month && birthday.day >= birthday.day)) ? 0 : 1)
    end
  end

  def creator_name(current_user)
    I18n.t('premium.titles.creator_name', :current_creator=>ContentCreator.find(current_user.content_creator_id).name)
  end

  def update_error_message(messages)
    updated_messages = []
    messages.each do |message|
      if message.include?('Discord')
        updated_messages << I18n.t('errors.titles.discord')
      end
      if message.include?('Psn')
        updated_messages << I18n.t('errors.titles.psn')
      end
      if message.include?('Xbox live')
        updated_messages << I18n.t('errors.titles.xbox')
      end
      if message.include?('Steam')
        updated_messages << I18n.t('errors.titles.steam')
      end
      if message.include?('Battle tag')
        updated_messages << I18n.t('errors.titles.battle')
      end
    end
    if messages.present? && updated_messages.blank?
      updated_messages = messages
    end
    updated_messages
  end
end
