class AnnictBackfillJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  # 過去分を1年ずつ遡って同期する。0件になったら遡及完了とみなし以後は何もしない
  def perform
    key = Setting::Keys::ANNICT_BACKFILL_NEXT_YEAR
    year = (Setting[key] || Time.current.year - 2).to_i
    return if year.zero?

    seasons = Annict::SyncAnimesService.seasons_for_year(year)
    total = Annict::SyncAnimesService.call(seasons:)
    Rails.logger.info "[AnnictBackfillJob] year=#{year} #{total} works processed."

    Setting[key] = total.zero? ? 0 : year - 1
  end
end
