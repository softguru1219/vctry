namespace :paypal do
  desc "TODO"
  task setup: :environment do
    # Create product
    product_id = Paypal::PaypalApi.new.create_memebership
    return {} unless product_id
    
    # Create plan with product id
    plan_resp = Paypal::PaypalApi.new.create_plan(product_id, name="Monthly plan", value="7.99", total_cycles=12, interval_unit="MONTH", currency_code="EUR")
    return {} unless plan_resp

    # Save to database the plan data
    save(plan_resp, interval='month', auto_renew=true)
  end

  def save(plan, interval, auto_renew)
    params = {
      :sb_plan_id => plan[:id],
      :name => plan[:name],
      :description => plan[:description],
      :status => plan[:status],
      :interval => Plan.intervals[interval],
      :auto_renew => auto_renew,
      :price_cents => 7.99
    }
    
    exist_plan = Plan.where(sb_plan_id: plan[:id], name: plan[:name])
    begin
      if exist_plan.present?
        exist_plan.first.update(params)
        puts 'Updated'
      else
        Plan.new(params).save
        puts 'Created'
      end
    rescue Exception => e
      puts e
    end
  end

  # rake paypal:oneTime_purchase_day_setup
  task oneTime_purchase_day_setup: :environment do
    product_id = Paypal::PaypalApi.new.create_memebership
    return {} unless product_id
    
    # Create plan with product id
    plan_resp = Paypal::PaypalApi.new.create_plan(product_id, name="One time Daily plan", value="3", total_cycles=0, interval_unit="DAY", currency_code="EUR")
    return {} unless plan_resp

    # Save to database the plan data
    save(plan_resp, 'day', false)
  end

  # rake paypal:oneTime_purchase_week_setup
  task oneTime_purchase_week_setup: :environment do
    product_id = Paypal::PaypalApi.new.create_memebership
    return {} unless product_id
    
    # Create plan with product id
    plan_resp = Paypal::PaypalApi.new.create_plan(product_id, name="One time Weekly plan", value="5", total_cycles=0, interval_unit="WEEK", currency_code="EUR")
    return {} unless plan_resp

    # Save to database the plan data
    save(plan_resp, 'week', false)
  end

  # rake paypal:oneTime_purchase_week_setup
  task oneTime_purchase_month_setup: :environment do
    product_id = Paypal::PaypalApi.new.create_memebership
    return {} unless product_id
    
    # Create plan with product id
    plan_resp = Paypal::PaypalApi.new.create_plan(product_id, name="One time Monthly plan", value="10", total_cycles=0, interval_unit="MONTH", currency_code="EUR")
    return {} unless plan_resp

    # Save to database the plan data
    save(plan_resp, 'month', false)
  end
end
