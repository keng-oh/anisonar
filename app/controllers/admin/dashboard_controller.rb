module Admin
  class DashboardController < BaseController
    def index
      @pending_songs_this_week = Song.pending_review.where(created_at: 1.week.ago..).count
      @approved_songs_count = Song.approved.count
      @approved_songs_this_month = Song.approved.where(updated_at: Time.current.beginning_of_month..).count
      @animes_count = Anime.count
      @annict_synced_count = Anime.where.not(annict_id: nil).count
      @artists_count = Artist.count

      @review_queue = Song.pending_review.includes(:artist, anime_songs: :anime).order(created_at: :asc).limit(8)

      @song_type_counts = AnimeSong.joins(:song).merge(Song.approved).group(:song_type).count
      @song_type_max = [ @song_type_counts.values.max.to_i, 1 ].max

      @crawl_total = CrawlRequest.count
      @crawl_done = CrawlRequest.done.count
      @crawl_in_progress = CrawlRequest.where(status: %w[pending crawling crawled extracting]).count
    end
  end
end
