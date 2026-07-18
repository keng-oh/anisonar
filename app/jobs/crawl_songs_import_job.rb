class CrawlSongsImportJob < ApplicationJob
  queue_as :ai_collection

  def perform(crawl_request_id, items)
    crawl_request = CrawlRequest.find(crawl_request_id)
    items = items.map(&:symbolize_keys)

    # 曲は artist 必須のため、AIがアーティスト名を特定できなかったitem（BGMトラック等）は保存対象外。
    # 期待される間引きなのでエラー扱いにはせずログのみ残す
    items, skipped = items.partition { |item| item[:title].present? && item[:artist_name].present? }
    skipped.each { |item| Rails.logger.info "[CrawlSongsImportJob] skip item without title/artist: #{item[:title].presence || '(no title)'}" }

    # AIが依頼対象外の anime_id を返すことがあるため、対象内のものだけ保存し、残りはエラーとして報告する
    allowed_anime_ids = crawl_request.target_animes.map(&:id)
    valid_items, invalid_items = items.partition { |item| item[:anime_id].blank? || allowed_anime_ids.include?(item[:anime_id].to_i) }

    songs_data = Songs::ArtistResolver.call(
      items: valid_items,
      anime: crawl_request.anime,
      anime_series: crawl_request.anime_series,
      user: User.ai_bot
    )
    result = Songs::BulkSaveService.call(songs_data: songs_data, user: User.ai_bot)

    result.saved.each { |song| resolve_spotify_track(song) }

    error_messages = result.failed.map { |f| f[:messages].join(", ") } +
      invalid_items.map { |item| "「#{item[:title]}」: 依頼対象外の anime_id=#{item[:anime_id]}" }

    if error_messages.empty?
      crawl_request.update!(status: :done)
    else
      crawl_request.update!(status: :failed, error_message: error_messages.join("; "))
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
