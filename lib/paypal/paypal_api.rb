module Paypal
  class PaypalApi
    def create_memebership
      if Rails.env.production?
        url = ENV['sb_prod_product_url']
      else
        url = ENV['sb_product_url']
      end
      data = {
        name: "VCTRY Premium Subscription",
        description: "Subscription for VCTRY Premium Subscription",
        type: "SERVICE",
        category: "SOFTWARE",
        image_url: "https://www.vctry.gg/premium-paypal.jpg",
        home_url: "https://www.vctry.gg"
      }
      
      resp_json ||= []
      
      access_info = sb_access_info
      return {} unless access_info

      token = access_info[:access_token]
      app_id = access_info[:app_id]

      begin
        response = HTTP.headers('Content-Type' => "application/json", 'Authorization' => "Bearer #{token}", 'PayPal-Request-Id' => "#{app_id}").post(url, json: data)
        resp_json = to_json(response)
      rescue Exception=>ex
        puts ex
        resp_json = {}
      end
      resp_json[:id]
    end

    def create_plan(product_id, name, value, total_cycles, interval_unit, currency_code)
      if Rails.env.production?
        url = ENV['sb_prod_plan_url']
      else
        url = ENV['sb_plan_url']
      end

      data = {
        product_id: product_id,
        name: name,
        description: name,
        billing_cycles: [
          {
            frequency: {
              interval_unit: interval_unit,
              interval_count: 1
            },
            tenure_type: "REGULAR",
            sequence: 1,
            total_cycles: total_cycles,
            pricing_scheme: {
              fixed_price: {
                value: value,
                currency_code: currency_code
              }
            }
          }
        ],
        payment_preferences: {
          auto_bill_outstanding: true,
          setup_fee: {
            value: "0",
            currency_code: currency_code
          },
          setup_fee_failure_action: "CONTINUE",
          payment_failure_threshold: 3
        }
      }

      access_info = sb_access_info
      return {} unless access_info

      token = access_info[:access_token]
      app_id = access_info[:app_id]

      begin
        response = HTTP.headers(
          'Content-Type' => "application/json", 
          'Authorization' => "Bearer #{token}", 
          'PayPal-Request-Id' => "#{app_id}",
          'Prefer' => "return=representation",
          'Accept' => "application/json"
        ).post(url, json: data)

        resp_json = to_json(response)
      rescue Exception=>ex
        puts ex
        resp_json = {}
      end
      resp_json
    end

    def validation_order(orderID)
      if Rails.env.production?
        url = ENV['paypal_prod_order_api'] + orderID
      else
        url = ENV['paypal_order_api'] + orderID
      end

      access_info = sb_access_info
      return {} unless access_info

      token = access_info[:access_token]
      begin
        response = HTTP.headers(
          'Authorization' => "Bearer #{token}", 
          'Accept' => "application/json"
        ).get(url)
      rescue Exception => exception
        Raven.capture_exception(exception)
      end
      response
    end

    def transaction_withdraw(params)
      sender_batch_id = "Payouts_#{params[:user_id]}_#{DateTime.now.strftime("%Y%m%dT%H%M")}"
      sender_item_id = "#{params[:user_id]}_#{DateTime.now.strftime("%Y%m%dT%H%M")}"
      response = nil
      if Rails.env.production?
        url = ENV['paypal_prod_payout_api']
      else
        url = ENV['paypal_payout_api']
      end
      access_info = sb_access_info
      return {} unless access_info

      token = access_info[:access_token]
      data = {
        sender_batch_header: {
          sender_batch_id: sender_batch_id,
          email_subject: "Your VCTRY withdrawal request was successful",
          email_message: "Your withdrawal request for VCTRY was successful, thanks for playing!"
        },
        items: [
          {
            recipient_type: "EMAIL",
            amount: {
              value: params[:amount].to_s,
              currency: "EUR"
            },
            note: "VCTRY wallet withdrawal request",
            sender_item_id: sender_item_id,
            receiver: params[:email],
            alternate_notification_method: {
              phone: {
                country_code: "91",
                national_number: "9999988888"
              }
            }
          }
        ]
      }
      
      begin
        response = HTTP.headers(
          'Content-Type' => "application/json", 
          'Authorization' => "Bearer #{token}", 
        ).post(url, json: data)
        # show_resp = show_paypout_details(response, token)
      rescue Exception=>ex
        puts ex
      end
      response
    end

    def cancel_subscription(subscription_id)
      if Rails.env.production?
        url = ENV['paypal_prod_cancel_subscription'] % subscription_id
      else
        url = ENV['paypal_cancel_subscription'] % subscription_id
      end
      access_info = sb_access_info
      return {} unless access_info

      token = access_info[:access_token]
      data = {reason: "Not satisfied with the service"}
      begin
        response = HTTP.headers(
          'Authorization' => "Bearer #{token}", 
          'Content-Type' => "application/json"
        ).post(url, json: data)
      rescue Exception=>ex
        puts ex
      end
      response
    end

    def show_paypout_details(response, token)
      if response.status == 201
        batch_id = JSON.parse(response.body.to_s)["batch_header"]["payout_batch_id"]
        url ="https://api.sandbox.paypal.com/v1/payments/payouts/#{batch_id}?fields=batch_header"
        
        response = HTTP.headers(
          'Content-Type' => "application/json", 
          'Authorization' => "Bearer #{token}", 
        ).get(url)
        
        response
      end
    end

    private

    def sb_access_info
      credentials = "username=#{ENV['PAYPAL_EMAIL']}&password=#{ENV['PAYPAL_PASSWORD']}&signature=#{ENV['PAYPAL_SIGNATURE']}"

      if Rails.env.production?
        auth_data = "#{ENV['sb_prod_client_id']}:#{ENV['sb_prod_client_secret']}"
        url = ENV['sb_prod_token_url']
      else
        auth_data = "#{ENV['sb_client_id']}:#{ENV['sb_client_secret']}"
        url = ENV['sb_token_url']
      end
      
      auth_data = Base64.strict_encode64(auth_data)
      
      data = {
        grant_type: "client_credentials"
      }

      begin
        response = HTTP['Content-Type' => "application/x-www-form-urlencoded", 'Authorization' => "Basic #{auth_data}"]
          .post(
            url, 
            :body => URI.encode_www_form(data)
          )
        resp_json = to_json(response)
      rescue Exception => ex
        puts ex
        resp_json = {}
      end

      resp_json
    end

    def to_json(response)
      begin
        resp_str_json = response.body.to_s
        resp_json = JSON.parse(resp_str_json).symbolize_keys
      rescue Exception => ex
        puts ex
        resp_json = {}
      end
      resp_json
    end
  end
end