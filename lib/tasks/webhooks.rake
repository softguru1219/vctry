namespace :webhooks do
  desc "TODO"
  task add: :environment do
    if ARGV.present?
      begin
        name = ARGV.second
        url = ARGV.last
        TournamentApi::DownUploadTournament.new.create_webhooks(name, url)
      rescue
      end
    end
  end

end
