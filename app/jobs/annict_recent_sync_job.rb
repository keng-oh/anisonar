class AnnictRecentSyncJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  # 放送中・放送予定（来年分まで）の更新を定期的に拾うためのジョブ
  def perform
    year = Time.current.year
    seasons = Annict::SyncAnimesService.seasons_for_year(year) +
              Annict::SyncAnimesService.seasons_for_year(year + 1)

    total = Annict::SyncAnimesService.call(seasons:)
    Rails.logger.info "[AnnictRecentSyncJob] Done. #{total} works processed."
  end
end
