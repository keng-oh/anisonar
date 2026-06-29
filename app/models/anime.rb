class Anime < ApplicationRecord
  belongs_to :anime_series, optional: true
  has_many :anime_songs, dependent: :destroy
  has_many :songs, through: :anime_songs
  has_many :artists, foreign_key: :anime_id, dependent: :nullify, inverse_of: :anime
  has_many :crawl_requests, dependent: :destroy

  enum :media_type, { tv: 0, movie: 1, ova: 2, ona: 3, special: 4 }
  enum :status, { airing: 0, finished: 1 }

  validates :title, presence: true
  validates :media_type, presence: true
  validates :annict_id, uniqueness: { allow_nil: true }

  SEASON_NAME_LABELS = { "spring" => "春", "summer" => "夏", "autumn" => "秋", "winter" => "冬" }.freeze

  # "2025-spring" => "2025年春", "2025-" => "2025年放送"
  def self.season_label(season)
    year, name = season.to_s.split("-")
    return season if year.blank?
    return "#{year}年放送" if name.blank?

    "#{year}年#{SEASON_NAME_LABELS.fetch(name, name)}"
  end

  scope :by_season, ->(season) { where(season:) }
  scope :airing, -> { where(status: :airing) }
  scope :search, ->(q) { where("title ILIKE :q OR title_en ILIKE :q", q: "%#{sanitize_sql_like(q)}%") }
  scope :by_popularity, -> { order(watchers_count: :desc) }

  # 自身の楽曲、もしくは所属シリーズの共通楽曲があるアニメのみ
  scope :with_songs, -> {
    where(
      "EXISTS (
         SELECT 1 FROM anime_songs
         WHERE anime_songs.anime_id = animes.id
       ) OR (
         animes.anime_series_id IS NOT NULL AND EXISTS (
           SELECT 1 FROM series_songs
           WHERE series_songs.anime_series_id = animes.anime_series_id
         )
       )"
    )
  }
end
