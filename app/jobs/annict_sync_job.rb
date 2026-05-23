class AnnictSyncJob < ApplicationJob
  queue_as :default

  def perform(seasons: nil)
    total = Annict::SyncAnimesService.call(seasons:)
    Rails.logger.info "[AnnictSyncJob] Done. #{total} works processed."
  end
end
