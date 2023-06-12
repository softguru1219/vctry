class Standing < ApplicationRecord
  belongs_to :tournament

  def self.get_standings(tournament)
    standing = TournamentApi::DownUploadTournament.new.get_standings tournament.toornament_id
    @standings = tournament.standings
    if @standings.present?
      @standings.destroy_all
    end
    save_standing(standing, tournament)
  end

  def self.save_standing(standing, tournament)
    begin
      standing.each do |st, index|
        params = st.symbolize_keys
        params[:toornament_standing_id] = params.delete :id
        participant = params[:participant]
        if participant.present?
          ptc_id = participant["custom_user_identifier"].split(':').last.to_i
          params[:ptc_id] = ptc_id
        end
        params.delete :participant
        params[:tournament_id] = tournament.id
        existing_standing = Standing.find_by(toornament_standing_id: params[:toornament_standing_id])
        if existing_standing.present?
          existing_standing.update(params)
        else
          s = Standing.new(params)
          s.save!
        end
      end
    rescue Exception => ex
      puts ex
    end
  end

  def self.winner(standings)
    username = 'Nickname'
    player = standings.select { |player| player.rank == 1 }
    if player.present?
      user_id = player.first.ptc_id
      username = User.where(:id=>user_id).present? ? User.find(user_id).username : 'Nickname'
    end
    username
  end

  def self.player(standing)
    User.where(id: standing.ptc_id).present? ? User.find(standing.ptc_id) : nil
  end
end
