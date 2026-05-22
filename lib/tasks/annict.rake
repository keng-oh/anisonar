namespace :annict do
  desc "Sync anime and series data from Annict API. Optionally filter by season: SEASON=2025-spring"
  task sync: :environment do
    seasons = ENV["SEASON"]&.split(",")&.map(&:strip)
    label = seasons ? "seasons: #{seasons.join(", ")}" : "all seasons"
    puts "Starting Annict sync (#{label})..."
    total = Annict::SyncAnimesService.call(seasons:)
    puts "Finished. #{total} works processed."
  end
end
