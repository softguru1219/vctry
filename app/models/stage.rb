class Stage < ApplicationRecord
  belongs_to :tournament
  
  def self.get_stages(tournament)
    stages = TournamentApi::DownUploadTournament.new.get_stages tournament.toornament_id
    save_stage(stages, tournament)
  end

  def self.save_stage(stages, tournament)
    begin
      stages.each do |stage, index|
        params = stage.symbolize_keys
        params[:toornament_stage_id] = params.delete :id
        params[:stage_type] = params.delete :type
        existing_stage = Stage.find_by(toornament_stage_id: params[:toornament_stage_id])
        if existing_stage
          existing_stage.update(params)
        else
          params[:tournament_id] = tournament.id
          stage_round = Stage.new(params)
          stage_round.save
        end
      end
    rescue Exception => ex
      puts ex
    end
  end

  def self.check_stages(tournament)
    TournamentApi::DownUploadTournament.new.get_stages tournament.toornament_id
  end
end
