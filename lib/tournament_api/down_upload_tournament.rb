module TournamentApi
  class DownUploadTournament
    # Get the all of tournaments from toornament api
    def get_tournaments(tournament_id)
      tournament_url = "https://api.toornament.com/organizer/v2/tournaments"
      if tournament_id.nil?
        after_date = 1.week.ago.strftime("%Y-%m-%d")
        tournament_url = "https://api.toornament.com/organizer/v2/tournaments?scheduled_after=#{after_date}"
      else
        tournament_url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}"
      end
      get_data(tournament_url, 'tournaments', tournament_id)
    end

    def get_single_tournaments(tournament_id)
      tournament_url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}"
      get_single_data(tournament_url, 'tournaments', tournament_id)
    end

    # Update the toornament with size
    def update_tournaments(tournament_id, size)
      tournament_url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}"
      tournament_data = {
        size: size
      }
      update_data(tournament_url, tournament_data)
    end

    # def update_tournament_description(tournament_id, description)
    #   tournament_url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}"
    #   tournament_data = {
    #     description: description
    #   }
    #   update_data(tournament_url, tournament_data)
    # end

    def get_participants(tournament_id)
      participant_url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}/participants"
      get_data(participant_url, 'participants', nil)
    end

    # Create the all of participants from toornament api
    def create_participants(tournament_id, current_user)
      participant_url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}/participants"
      participant_data = {
        name: current_user.username,
        email: current_user.email,
        custom_user_identifier: "vctry:account:#{current_user.id}", 
        checked_in: false,
        custom_fields: {}
      }
      create_data(participant_url, participant_data)
    end

    # Update the Participant
    def update_participants(tournament_id, current_user, participant)
      if participant.present?
        participant_id = participant.partic_id
        participant_url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}/participants/#{participant_id}"
        participant_data = {
          name: current_user.username,
          email: current_user.email,
          custom_user_identifier: "vctry:account:#{current_user.id}", 
          checked_in: true,
          custom_fields: {}
        }

        update_data(participant_url, participant_data)
      end
    end

    def delete_participants(tournament_id, participant)
      participant_id = participant.partic_id
      participant_url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}/participants/#{participant_id}"
      delete_data(participant_url)
    end
    
    # Get the Match data from toornament api
    def get_matches(tournament_id)
      match_url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}/matches"
      get_data(match_url, 'matches', nil)
    end

    def get_single_match(tournament_id, match_id)
      match_url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}/matches/#{match_id}"
      # get_data(match_url, 'matches', tournament_id)
      get_single_data(match_url, 'matches', tournament_id)
    end

    def update_matches(tournament_id, matches)
      url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}/matches/#{matches.toornament_match_id}"
      matches['scheduled_datetime'] = matches["scheduled_datetime"].to_s
      data = {
        opponents: matches[:opponents],
        status: matches[:status]
      }
      update_data(url, data)
    end

    def get_rounds(tournament_id)
      round_url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}/rounds"
      get_data(round_url, 'rounds', nil)
    end

    def get_stages(tournament_id)
      stage_url = "https://api.toornament.com/organizer/v2/tournaments/#{tournament_id}/stages"
      get_single_data(stage_url, 'stages', tournament_id)
    end

    def get_standings(tournament_id)
      url = "https://api.toornament.com/organizer/v2/standings?tournament_ids=#{tournament_id}"
      get_data(url, 'items', nil)
    end
    
    # Create webhooks
    def create_webhooks(name, url)
      webhooks_url = 'https://api.toornament.com/organizer/v2/webhooks'
      webhooks_data = {
        "enabled": true,
        "name": name,
        "url": url.gsub("/","\/")
      }

      create_data(webhooks_url, webhooks_data)
    end

    # Get Subscription for webhook

    private

    # Authentication for tournaments api and Get auth token
    def tournament_auth_token
      scope = %w[
        organizer:view
        participant:manage_registrations
        participant:manage_participations
        user:info
        organizer:admin
        organizer:result
        organizer:participant
        organizer:registration
        organizer:permission
      ]

      auth_data = {
        grant_type: 'client_credentials',
        client_id: ENV['TOUR_CLIENT_ID'],
        client_secret: ENV['TOUR_CLIENT_SECRET'],
        scope: scope.join(' ')
      }

      begin
        response = HTTP['Content-Type' => "application/x-www-form-urlencoded"]
          .post(
            ENV['TOUR_AUTH_URL'],
            :body => URI.encode_www_form(auth_data)
          )

        resp_str_json = response.body.to_s
        resp_json = JSON.parse(resp_str_json).symbolize_keys
      rescue Exception=>ex
        puts ex
        resp_json = {}
      end

      resp_json[:access_token]
    end

    def get_data(url, organizer, tournament_id)
      resp_json ||= []
      
      token = tournament_auth_token
      return {} unless token
      organizer_min = 0
      no_limit = true

      total_json ||= []

      begin
        while no_limit do
          organizer_max = organizer_min + 49
          if tournament_id.present?
            response = HTTP.headers('X-Api-Key' => ENV['TOUR_API'], 'Authorization' => token).get(url)
          else
            response = HTTP.headers('X-Api-Key' => ENV['TOUR_API'], 'Authorization' => token, 'Range'=> "#{organizer}=#{organizer_min}-#{organizer_max}").get(url)
          end
          
          resp_str_json = response.body.to_s

          if is_json(resp_str_json)
            resp_json = JSON.parse(resp_str_json)
          end

          if resp_json.length < 50
            no_limit = false
          else
            organizer_min = organizer_max + 1
          end

          if resp_json.length > 0 && resp_json.kind_of?(Array)
            begin
              total_json += resp_json
            rescue Exception => exception
              Raven.capture_exception(exception)
              no_limit = false
            end
          end
        end
      rescue Exception => exception
        Raven.capture_exception(exception)
        no_limit = false
      end
      total_json
    end

    def get_single_data(url, organizer, tournament_id)
      resp_json ||= []
      
      token = tournament_auth_token
      return {} unless token

      begin
        response = HTTP.headers('X-Api-Key' => ENV['TOUR_API'], 'Authorization' => token).get(url)
        resp_str_json = response.body.to_s
        if is_json(resp_str_json)
          resp_json = JSON.parse(resp_str_json)
        end

      rescue Exception => exception
        Raven.capture_exception(exception)
        resp_json = {}
      end
      resp_json
    end

    def create_data(url, organizer_data)
      resp_json ||= []
      
      token = tournament_auth_token
      return {} unless token

      begin
        response = HTTP.headers('X-Api-Key' => ENV['TOUR_API'], 'Authorization' => "Bearer #{token}").post(url, json: organizer_data)
        resp_str_json = response.body.to_s
        resp_json = JSON.parse(resp_str_json).symbolize_keys
      rescue Exception => exception
        Raven.capture_exception(exception)
        resp_json = {}
      end
    end

    def update_data(url, organizer_data)
      resp_json ||= []
      
      token = tournament_auth_token
      return {} unless token

      begin
        response = HTTP.headers('X-Api-Key' => ENV['TOUR_API'], 'Authorization' => "Bearer #{token}").patch(url, json: organizer_data)
        resp_str_json = response.body.to_s
        resp_json = JSON.parse(resp_str_json).symbolize_keys
      rescue Exception=>ex
        Raven.capture_exception(ex)
        resp_json = {}
      end
      resp_json
    end

    def delete_data(url)
      resp_json ||= []
      
      token = tournament_auth_token
      return {} unless token

      begin
        response = HTTP.headers('X-Api-Key' => ENV['TOUR_API'], 'Authorization' => "Bearer #{token}").delete(url)
        resp_str_json = response.body.to_s
        resp_json = JSON.parse(resp_str_json).symbolize_keys
      rescue Exception => exception
        Raven.capture_exception(exception)
        resp_json = {}
      end
    end

    def is_json(foo)
      begin
        return false unless foo.is_a?(String)
        JSON.parse(foo).all?
      rescue JSON::ParserError
        false
      end 
    end
  end
end
