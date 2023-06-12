class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :plan, optional: true
  belongs_to :tournament, optional: true

  enum status: {active: 0, inactive: 1, canceled: 2}

  def self.last_expires_date(current_user)
    last_expires_date = current_user.subscriptions.order('expires_on DESC')
    if last_expires_date.present?
      last_expires_date = last_expires_date.first.expires_on
    else
      last_expires_date = DateTime.now.utc
    end
    last_expires_date
  end
end
