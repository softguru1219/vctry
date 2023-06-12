class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  
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
end
