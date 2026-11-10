class Song < ApplicationRecord
  belongs_to :artist
  belongs_to :album, optional: true
  belongs_to :created_by_user, class_name: "User", optional: true
  belongs_to :updated_by_user, class_name: "User", optional: true
  has_many :anime_songs, dependent: :destroy
  has_many :animes, through: :anime_songs
  has_many :series_songs, dependent: :destroy
  has_many :anime_series, through: :series_songs
  has_many :platform_links, dependent: :destroy
  has_many :platform_link_attempts, dependent: :destroy

  delegate :name, :image_url, :release_date, to: :album, prefix: true, allow_nil: true

  validates :title, presence: true

  scope :search, ->(q) { joins(:artist).where("songs.title ILIKE :q OR artists.name ILIKE :q", q: "%#{sanitize_sql_like(q)}%") }
  scope :by_song_type, ->(type) {
    where(id: AnimeSong.where(song_type: type).select(:song_id))
      .or(where(id: SeriesSong.where(song_type: type).select(:song_id)))
  }

  # 紐づいたアニメのタイトル、紐づいたシリーズの名前、そのシリーズに属するアニメのタイトルのどれかに部分一致する曲
  scope :by_anime_title, ->(q) {
    pattern = "%#{sanitize_sql_like(q)}%"
    animes = Anime.where("title ILIKE :q OR title_en ILIKE :q", q: pattern)
    series_ids = AnimeSeries.where("name ILIKE :q", q: pattern)
                            .or(AnimeSeries.where(id: animes.select(:anime_series_id)))
                            .select(:id)

    where(id: AnimeSong.where(anime_id: animes.select(:id)).select(:song_id))
      .or(where(id: SeriesSong.where(anime_series_id: series_ids).select(:song_id)))
  }

  # 曲ごとに、紐づいたアニメと紐づいたシリーズに属するアニメの watchers_count の最大値で並べる。紐づきの無い曲は最後
  scope :order_by_anime_popularity, -> {
    popularity = <<~SQL.squish
      (SELECT MAX(a.watchers_count) FROM animes a
        WHERE a.id IN (SELECT anime_id FROM anime_songs WHERE anime_songs.song_id = songs.id)
           OR a.anime_series_id IN (SELECT anime_series_id FROM series_songs WHERE series_songs.song_id = songs.id))
    SQL
    order(Arel.sql("#{popularity} DESC NULLS LAST"), created_at: :desc)
  }
  scope :spotify_unlinked, -> { where.not(id: PlatformLink.spotify.select(:song_id)) }
  scope :spotify_untried, -> { spotify_unlinked.where.not(id: PlatformLinkAttempt.spotify.select(:song_id)) }
  scope :spotify_not_found, -> { spotify_unlinked.where(id: PlatformLinkAttempt.spotify.select(:song_id)) }

  # 一覧で includes(:platform_links) 済みなら、曲ごとにクエリを発行しない
  def spotify_link
    return platform_links.find(&:spotify?) if platform_links.loaded?

    platform_links.find_by(platform: :spotify)
  end

  def spotify_url
    link = spotify_link
    "https://open.spotify.com/track/#{link.platform_track_id}" if link
  end
end
