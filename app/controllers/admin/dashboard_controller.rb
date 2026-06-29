module Admin
  class DashboardController < BaseController
    def index
      @songs_this_week = Song.where(created_at: 1.week.ago..).count
      @songs_count = Song.count
      @songs_this_month = Song.where(created_at: Time.current.beginning_of_month..).count
      @animes_count = Anime.count
      @annict_synced_count = Anime.where.not(annict_id: nil).count
      @artists_count = Artist.count

      @recent_songs = Song.includes(:artist, anime_songs: :anime).order(created_at: :desc).limit(8)

      @song_type_counts = AnimeSong.group(:song_type).count
      @song_type_max = [ @song_type_counts.values.max.to_i, 1 ].max

      @crawl_total = CrawlRequest.count
      @crawl_done = CrawlRequest.done.count
      @crawl_in_progress = CrawlRequest.where(status: %w[pending crawling crawled extracting]).count
    end
  end
end
