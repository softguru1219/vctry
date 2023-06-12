class Coupon < ApplicationRecord
  belongs_to :creator, class_name: "User", optional: true
  enum interval: {day: 0, week: 1, month: 2, year: 3}

  attr_accessor :bulk_generation
  attr_accessor :quantity

  def end_date_from(date = nil)
    date ||= Date.current.to_date
    interval_count ||= 1
    case self.interval
      when "day"
        return date + interval_count.day
      when "week"
        return date + interval_count.week
      when "month"
        return date + interval_count.month
      when "year"
        return date + interval_count.year
      else
    end
  end

  def self.current_coupon(params)
    Coupon.find_by(coupon_code: params[:promoCode], one_use: true)
  end

  def self.redeemed_interval(params)
    interval = Coupon.current_coupon(params).interval
    if interval == 'week'
      result = "7 #{I18n.t('homepage.titles.days')}"
    elsif interval == 'month'
      result = "30 #{I18n.t('homepage.titles.days')}"
    else
      result = "1 #{I18n.t('homepage.titles.day')}"
    end
    result
  end

  def bulk_generation= (attributes)
  end

  def quantity= (attributes)
  end
end
