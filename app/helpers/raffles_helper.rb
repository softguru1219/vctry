module RafflesHelper

  def selected_raffle_date(raffle, params)
    result = false
    selected_date = params[:date]
    raffle_date = raffle.raffle_end_date.to_date.strftime('%F')
    if selected_date == raffle_date
      result = true
    end

    result
  end

  def exist_raffle_winner
    current_user.raffle_winners.where(raffle_id: @current_raffle)
  end
end