class TournamentsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, :only => [:match_update_status, :refresh_tournament, :save_stage]
  # skip_before_action :authenticate_user!, :only => [:show]
  # skip_authorize_resource :only => [:index, :show]
  include TournamentsHelper

  def index
    @tournaments = Tournament.where(visible: true)
    @is_desktop = is_desktop
    if params[:game].present?
      @tournaments = @tournaments.where(discipline: params[:game])
    end
    @free_tournaments = Tournament.where(visible: true).where('price = ?', 0)
    if @free_tournaments.present?
      if params[:game].present?
        @free_tournaments = @free_tournaments.where(discipline: params[:game]).order("registration_closing_datetime ASC")
      else
        @free_tournaments = @free_tournaments.order("registration_closing_datetime ASC")
      end
    end
    @paid_tournaments = Tournament.where(visible: true).where('price > ?', 0)
    if @paid_tournaments.present?
      if params[:game].present?
        @paid_tournaments = @paid_tournaments.where(discipline: params[:game]).order("registration_closing_datetime ASC")
      else
        @paid_tournaments = @paid_tournaments.order("registration_closing_datetime ASC")
      end
    end
  end

  def filtered_tournaments
    @filtered_tournaments = Tournament.all
    @paid_mode = params[:paid_mode]
    if params[:filter].present?
      # @filtered_tournaments = Tournament.where('lower(discipline) IN (?)', params[:filter])
      array_with_game_ids = params[:filter].map {|val| "%#{val}%" }
      @filtered_tournaments = Tournament.where("discipline ILIKE ANY ( array[?] )", array_with_game_ids)
    end

    if @paid_mode.present?
      @filtered_tournaments = @filtered_tournaments.where('price > ?', 0)
    else
      @filtered_tournaments = @filtered_tournaments.where('price = ?', 0)
    end
    
    if @filtered_tournaments.present?
      @filtered_tournaments = @filtered_tournaments.where(visible: true).order("registration_closing_datetime ASC")
    end

    @window_mode = @paid_mode.present? ? "#{params[:window_mode]}_#{@paid_mode}" : params[:window_mode]
    @tabcontent = @paid_mode.present? ? "#{@paid_mode}_tabcontent" : "tabcontent"
    render layout: false
  end

  def show
    @tournament = Tournament.find(params[:id])
    if @tournament.status == 'completed'
      redirect_to tournament_final_path(@tournament)
    else
      @participants = @tournament.participants
      if current_user.present?
        @current_participant = @participants.where(:user_id=>current_user.id)
        if @current_participant.present?
          if @current_participant.first.checked_in == true
            redirect_to tournament_checkin_path(@tournament)
          else
            redirect_to tournament_register_path(@tournament)
          end
        end
      end
    end
  end
  
  def join_tournament
    @tournament = Tournament.find(params[:id])
    if @tournament.status == 'completed'
      redirect_to tournament_final_path(@tournament)
    elsif @tournament.single_play == true
      active_tournament, single_play_alert = Tournament.active_tournament(current_user, @tournament)
      if active_tournament == true
        flash[:single_play] = single_play_alert
        redirect_to tournament_path(@tournament)
      else
        @participants = @tournament.participants
        @participant = @participants.where(:user_id=>current_user.id)
        if @tournament.registration_closing_datetime < Time.now.utc || (@tournament.participants.present? && @tournament.size <= @tournament.participants.length)
          redirect_to tournament_path(@tournament)
        else
          is_stream, stream_alert = Tournament.stream_check(@tournament, current_user)
          if is_stream == false
            flash[:stream_alert] = stream_alert
            redirect_to tournament_path(@tournament)
          end
          @participants = @tournament.participants
        end
      end
    else
      @participants = @tournament.participants
      @participant = @participants.where(:user_id=>current_user.id)
      if @tournament.registration_closing_datetime < Time.now.utc || (@tournament.participants.present? && @tournament.size <= @tournament.participants.length)
        redirect_to tournament_path(@tournament)
      else
        is_stream, stream_alert = Tournament.stream_check(@tournament, current_user)
        if is_stream == false
          flash[:stream_alert] = stream_alert
          redirect_to tournament_path(@tournament)
        end
        @participants = @tournament.participants
      end
    end
  end

  def tournament_register
    @tournament = Tournament.find(params[:id])
    if @tournament.status == 'completed'
      redirect_to tournament_final_path(@tournament)
    elsif @tournament.premium == true && !current_user.subscriptions.present?
      redirect_to tournament_path(@tournament)
    elsif  @tournament.price > 0 && paid_tournament(@tournament) == false
      redirect_to tournament_path(@tournament)
    else
      @participants = @tournament.participants
      @participant = @participants.where(:user_id=>current_user.id)
      if !@participant.present?
        if @tournament.registration_closing_datetime < Time.now.utc || (@tournament.participants.present? && @tournament.size <= @tournament.participants.length)
          redirect_to tournament_path(@tournament)
        elsif @tournament.single_play == true && Tournament.active_tournament(current_user, @tournament)[0] == true
          redirect_to tournament_path(@tournament)
        else
          Participant.create_participants(@tournament, current_user)
        end
      end

      @participants = @tournament.participants
      @participant = @participants.where(:user_id=>current_user.id)
      if @participant.present?
        if @participant.first.checked_in == true
          redirect_to tournament_checkin_path(@tournament)
        # elsif @tournament.check_in_participant_end_datetime.present? && @participant.present?
        #   if @tournament.check_in_participant_end_datetime < Time.now.utc && @participant.first.checked_in == false
        #     # Participant.delete_participants(@tournament, current_user)
        #     redirect_to tournaments_path
        #   end
        end
      end
    end
  end
  
  def tournament_checkin
    @tournament = Tournament.find(params[:id])
    if @tournament.status == 'completed'
      @existing_notifications = current_user.notifications.where(tournament_id: @tournament.id)
      if @existing_notifications.present?
        @existing_notifications.destroy_all
      end
      redirect_to tournament_final_path(@tournament)
    else
      @participants = @tournament.participants
      @participant = @participants.where(:user_id=>current_user.id)
      if @participant.present?
        if @tournament.check_in_participant_end_datetime < Time.now.utc && @participant.first.checked_in == false
          redirect_to tournament_path(@tournament)
        else
          # Get the next match
          @next_match = Match.next_match(@tournament, current_user).present? ? Match.next_match(@tournament, current_user).first : nil
          @running_next_match = Match.running_next_match(@tournament, current_user).present? ? Match.running_next_match(@tournament, current_user).first : nil

          if @next_match.present?
            if @next_match.scheduled_datetime.blank?
              if @participant.present?
                if @participant.first.checked_game == false
                  if @tournament.check_in_participant_end_datetime < Time.now.utc
                    @match_scheduled_time = Time.now.utc
                  else
                    @match_scheduled_time = @tournament.check_in_participant_end_datetime
                  end
                else
                  @match_scheduled_time = Time.now.utc
                end
              end
              @next_match.scheduled_datetime = @match_scheduled_time
              @next_match.save!
            else
              @match_scheduled_time = @next_match.scheduled_datetime
            end
            
            # Time to check the current match
            if Match.delay_time(@match_scheduled_time, @participant) + 10.minutes < Time.now.utc
              if Match.full_status_check(@next_match, current_user) == false
                @existing_notifications = current_user.notifications.where(tournament_id: @tournament.id)
                if @existing_notifications.present?
                  @existing_notifications.destroy_all
                end

                Match.update_before_match(@tournament, @next_match, current_user)
                @participant.first.checked_game = true
                @participant.first.had_game = true
                @participant.first.save!
                redirect_to tournament_checkin_path(@tournament)
              else
                redirect_to tournament_round_path(@tournament, @next_match)
              end
            else
              @existing_notifications = current_user.notifications.where(tournament_id: @tournament.id)
              if @existing_notifications.blank? && Match.status_check_in(@next_match, current_user) == false
                @notification = Notification.new
                @notification.user_id = current_user.id
                @notification.tournament_id = @tournament.id
                @notification.save!
              end
            end
          elsif @tournament.check_in_participant_end_datetime < Time.now.utc && @participant.first.checked_game == false
            @participant.first.checked_game = true
            @participant.first.save!
          end
        end
      else
        redirect_to tournament_path(@tournament)
      end
    end
  end
  
  def tournament_cancel
    @tournament = Tournament.find(params[:id])
    @participants = @tournament.participants
    @participant = @participants.where(:user_id=>current_user.id)
    if @tournament.status == 'completed'
      redirect_to tournament_final_path(@tournament)
    elsif @participant.present?
      if @tournament.price == 0
        Participant.delete_participants(@tournament, current_user)
        flash[:leave_tournament] = I18n.t('flash.titles.leave_tournament')
        redirect_to tournaments_path
      end
    else
      redirect_to tournaments_path
    end
  end

  def tournament_round
    @tournament = Tournament.find(params[:id])
    # Match.update_match_status(@tournament, Match.find(params[:match_id]), current_user)
    if @tournament.status == 'completed'
      redirect_to tournament_final_path(@tournament)
    else
      begin
        if Match.where(id: params[:match_id]).present?
          if @tournament.last_queried.present?
            if (Time.now.utc - @tournament.last_queried) > 10.seconds
              Match.get_matches(@tournament, current_user)
              @tournament.last_queried = Time.now.utc
              @tournament.save!
            end
          else
            Match.get_matches(@tournament, current_user)
            @tournament.last_queried = Time.now.utc
            @tournament.save!
          end

          if Match.where(id: params[:match_id]).present?
            single_match_status = Match.single_match_status(@tournament, Match.find(params[:match_id]))
            @match = Match.find(params[:match_id])
            if single_match_status == true
              if @match.present?
                @match.delete
              end
              flash[:remove_match] = I18n.t('flash.titles.remove_match')
              redirect_to tournament_path(@tournament)
            else
              if @match.status == "completed"
                redirect_to tournament_completed_match_path(@tournament, @match)
              else
                @participants = @tournament.participants
                @participant = @participants.where(:user_id=>current_user.id)
                # Match.update_match_status(@tournament, Match.find(params[:match_id]), current_user)

                if @match.status == 'pending' && Match.delay_time(@match.scheduled_datetime, @participant) + 10.minutes < Time.now.utc
                  if Match.full_status_check(@match, current_user) == false
                    redirect_to tournament_completed_match_path(@tournament, @match)
                  end
                elsif @match.status == 'running'
                  if !@match.submitter.nil? && !@match.confirmer.nil?
                    redirect_to tournament_completed_match_path(@tournament, @match)
                  elsif !@match.submitter.nil? && @match.confirmer.nil? && Match.confirm_time(@match).present?
                    if Match.confirm_time(@match) < Time.now.utc
                      redirect_to tournament_completed_match_path(@tournament, @match)
                    end
                  end
                elsif @match.status == 'completed'
                  redirect_to tournament_completed_match_path(@tournament, @match)
                end
              end
            end
          else
            flash[:remove_match] = I18n.t('flash.titles.remove_match')
            redirect_to tournament_path(@tournament)
          end
        else
          flash[:remove_match] = I18n.t('flash.titles.remove_match')
          redirect_to tournament_path(@tournament)
        end
      rescue Exception => exception
        Raven.capture_exception(exception)
      end
    end
  end

  def tournament_match_check
    @tournament = Tournament.find(params[:id])
    if @tournament.status == 'completed'
      redirect_to tournament_final_path(@tournament)
    else
      @match = Match.find(params[:match_id])

      @existing_notifications = current_user.notifications.where(tournament_id: @tournament.id)
      if @existing_notifications.present?
        @existing_notifications.destroy_all
      end

      Match.update_check(@tournament, @match, current_user)
      if Match.full_status_check(@match, current_user) == true && @match.status == 'pending'
        Match.update_match_status(@tournament, Match.find(params[:match_id]), current_user)
        ActionCable.server.broadcast "room_channel_#{@match.id}", message: { action: "check_in_finished", url: tournament_round_path(@tournament, @match) }
        redirect_to tournament_round_path(@tournament, @match)
      else
        redirect_to tournament_round_path(@tournament, @match)
      end
    end
  end

  def tournament_completed_match
    @tournament = Tournament.find(params[:id])
    if @tournament.status == 'completed'
      redirect_to tournament_final_path(@tournament)
    else
      if Match.where(id: params[:match_id]).present?
        if @tournament.last_queried.present?
          if (Time.now.utc - @tournament.last_queried) > 10.seconds
            Match.get_matches(@tournament, current_user)
            @tournament.last_queried = Time.now.utc
            @tournament.save!
          end
        else
          Match.get_matches(@tournament, current_user)
          @tournament.last_queried = Time.now.utc
          @tournament.save!
        end

        if Match.where(id: params[:match_id]).present?
          single_match_status = Match.single_match_status(@tournament, Match.find(params[:match_id]))
          @match = Match.find(params[:match_id])
          if single_match_status == true
            if @match.present?
              @match.delete
            end
            flash[:remove_match] = I18n.t('flash.titles.remove_match')
            redirect_to tournament_path(@tournament)
          else
            @participants = @tournament.participants
            @participant = @participants.where(:user_id=>current_user.id)
            
            if @tournament.last_queried.present?
              if (Time.now.utc - @tournament.last_queried) > 10.seconds
                Stage.get_stages(@tournament)
              end
            end
            
            if @match.status != "completed"
              if !@match.scores.present?
                @match.scores = Match.draw_scores(@match)
              end
              if @match.scores.present?
                resp = Match.update_match_score(@tournament, @match, current_user, @participant)
                if resp.present?
                  errors = resp.first || resp.last
                  flash[:error_message] = errors ? errors["message"] : Match::ERROR_MESSAGE
                else
                  flash[:error_message] = nil
                end
              end
            else
              if @match.played_at.blank?
                @match.played_at = Time.now.utc
              end
              if @match.scheduled_datetime.present? && @match.played_at.present?
                if @match.scheduled_datetime == @match.played_at
                  @match.played_at = Time.now.utc
                end
              end
              @match.scores = Match.admin_scores(@match)
              @match.save!
              if @participant.present?
                @participant.first.checked_game = true
                @participant.first.had_game = true
                @participant.first.save!
              end
            end
          end
        else
          flash[:remove_match] = I18n.t('flash.titles.remove_match')
          redirect_to tournament_path(@tournament)
        end
      else
        flash[:remove_match] = I18n.t('flash.titles.remove_match')
        redirect_to tournament_path(@tournament)
      end
    end
  end

  def submit_score
    @tournament = Tournament.find(params[:id])
    @match = Match.find(params[:match_id])
    @match.scores = Match.scores(@match, params)
    @match.submitter_id = current_user.id
    @match.played_at = Time.now.utc
    @match.save!
    # ActionCable.server.broadcast "room_channel_#{@match.id}", message: { action: "submitted the score" }
    ActionCable.server.broadcast "room_channel_#{@match.id}", message: { action: "submitted the score", url: tournament_round_path(@tournament, @match) }
    redirect_to tournament_round_path(@tournament, @match)
  end

  def confirm_score
    @tournament = Tournament.find(params[:id])
    @match = Match.find(params[:match_id])
    @match.confirmer_id = current_user.id
    # @match.played_at = Time.now.utc
    @match.save!
    ActionCable.server.broadcast "room_channel_#{@match.id}", message: { action: "confirmed the score", url: tournament_completed_match_path(@tournament, @match) }
    redirect_to tournament_completed_match_path(@tournament, @match)
  end

  # ajax
  def match_update_status
    @match = Match.find(params[:match_id])
    # @match.status = params[:status]
    # @match.played_at = Time.now.utc
    if @match.host.nil?
      @match.host_id = current_user.id
      # @match.played_at = Time.now.utc
      @match.save!
      render json: { status: :ok }
    elsif @match.host == current_user
      render json: { status: :ok }
    else
      render json: { status: :failed }
    end
  end

  def tournament_final
    @tournament = Tournament.find(params[:id])
    # if @tournament.standings.blank?
    # Standing.get_standings(@tournament)
    # end
    @standings = Standing.where(tournament_id: @tournament.id)

    if @standings.present?
      @standings = @standings.sort_by { |k| k["rank"] }
    end
    @participants = @tournament.participants
    if current_user.present?
      @current_participant = @participants.where(:user_id=>current_user.id)
      # Round.get_rounds(@tournament)
      # Stage.get_stages(@tournament)
    end
  end

  def standing
    @tournament = Tournament.find(params[:id])
    @standings = @tournament.standings
    if @standings.present?
      @standings = @standings.sort_by { |k| k["rank"] }
    end
  end

  def save_stage
    @tournament = Tournament.find(params[:tournament_id])
    if @tournament.stages.blank?
      Stage.get_stages(@tournament)
    end
    render json: {status: :ok}
  end
  
  def refresh_tournament
    @tournament = Tournament.find(params[:tournament_id])
    @participants = @tournament.participants
    @participant = @participants.find_by(:user_id=>current_user.id)

    # Update the checked participant
    if @participant.checked_in == false
      Participant.update_participants(@tournament, current_user)
      @participants = @tournament.participants
    end
    
    # Update the size of tournament if different
    checked_participants = @participants.where(checked_in: true)
    # Tournament.update_tournaments(@tournament, checked_participants.length)

    if @tournament.last_queried.present?
      if (Time.now.utc - @tournament.last_queried) > 10.seconds
        Stage.get_stages(@tournament)
        Round.get_rounds(@tournament)
        Match.get_matches(@tournament, current_user)
        @tournament.last_queried = Time.now.utc
        @tournament.save!
      end
    else
      Stage.get_stages(@tournament)
      Match.get_matches(@tournament, current_user)
      Round.get_rounds(@tournament)
      @tournament.last_queried = Time.now.utc
      @tournament.save!
    end

    # Get the next match
    @next_match = Match.next_match(@tournament, current_user).present? ? Match.next_match(@tournament, current_user).first : nil
    if @next_match.present? && @next_match.found_match == false
      players = Tournament.next_match_players(@next_match)
      if players.present?
        @next_match.found_match = true
        @next_match.save!
        ActionCable.server.broadcast "room_channel_#{@tournament.id}", message: { action: "match_ready", players: players, url: tournament_checkin_path(@tournament) }
        render json: {status: :ok}
      else
        render json: {status: :ok}
      end
    else
      render json: {status: :ok}
    end
  end
end
