class CrawlSongsImportJob < ApplicationJob
  queue_as :ai_collection

  def perform(crawl_request_id, items)
    crawl_request = CrawlRequest.find(crawl_request_id)
    items = items.map(&:symbolize_keys)

    songs_data = Songs::ArtistResolver.call(items: items, anime: crawl_request.anime, user: User.ai_bot)
    result = Songs::BulkSaveService.call(songs_data: songs_data, user: User.ai_bot)

    result.saved.each { |song| resolve_spotify_track(song) }

    if result.failed.empty?
      crawl_request.update!(status: :done)
    else
      crawl_request.update!(status: :failed, error_message: result.failed.map { |f| f[:messages].join(", ") }.join("; "))
    end
  rescue => e
    crawl_request&.update!(status: :failed, error_message: "予期しないエラー: #{e.message}")
    raise
  end

  private

    def resolve_spotify_track(song)
      Spotify::TrackResolver.call(song: song)
    rescue Spotify::Client::Error => e
      Rails.logger.warn "[CrawlSongsImportJob] song_id=#{song.id} spotify track resolve failed: #{e.message}"
    end
end
