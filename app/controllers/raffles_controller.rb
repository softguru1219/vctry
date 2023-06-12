class RafflesController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, :only => [:get_raffles, :update_chances, :generate_winners]

  def index
    @raffles = Raffle.all
    @current_raffle = Raffle.current_raffle
    @past_raffles = Raffle.past_raffles
    @closest_raffle_winners = Raffle.closest_raffle_winners
  end
  
  def show
    @raffle = Raffle.find(params[:id])
    @raffle_winners = Raffle.raffle_winners @raffle
  end

  def past_raffles
    @past_raffles = Raffle.past_raffles
  end

  def get_raffles
    @past_raffles = Raffle.past_raffles
    render layout: false
  end

  def update_chances
    if current_user.raffle_winners.where(raffle_id: params[:raffle_id]).blank?
      resp = RaffleWinner.update_chances(params, current_user.id)
      if resp
        current_user.tickets = current_user.tickets - params[:tickets].to_i
        current_user.save!
        render json: { status: :ok, tickets: current_user.tickets }
      else
        render json: { status: :failed }
      end
    else
      render json: { status: :failed }
    end
  end

  def generate_winners
    raffle_id = params[:raffle_id]
    numbers_of_winners = params[:winner_numbers].to_i
    status, result = Raffle.generate_winners(raffle_id, numbers_of_winners)
    render json: {status: status, result: result}
  end
end
