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
  # 編集画面の年・季節セレクト用。season は "2025-spring" / "2025-"（年だけ）の形
  def season_year
    season.to_s.split("-", 2).first.presence
  end

  def season_name
    season.to_s.split("-", 2)[1].presence
  end

  def season_year=(value)
    assign_season(value.to_s.strip.presence, season_name)
  end

  def season_name=(value)
    assign_season(season_year, value.to_s.strip.presence)
  end

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
  scope :by_year, ->(year) { where("animes.season LIKE ?", "#{year.to_i}-%") }
  scope :by_season_name, ->(name) { where("animes.season LIKE ?", "%-#{sanitize_sql_like(name.to_s)}") }

  # クロール依頼の有無・状態。シリーズ所属アニメはシリーズ単位で依頼するので、シリーズへの依頼も見る
  scope :with_crawl_status, ->(statuses) {
    requests = CrawlRequest.where(status: statuses)
    where(id: requests.where.not(anime_id: nil).select(:anime_id))
      .or(where(anime_series_id: requests.where.not(anime_series_id: nil).select(:anime_series_id)))
  }
  scope :without_crawl_request, -> {
    where.not(id: CrawlRequest.where.not(anime_id: nil).select(:anime_id))
      .where("animes.anime_series_id IS NULL OR animes.anime_series_id NOT IN (?)",
             CrawlRequest.where.not(anime_series_id: nil).select(:anime_series_id))
  }

  SEASON_NAMES_IN_ORDER = %w[winter spring summer autumn].freeze

  # today のシーズンまでの、直近 years 年分のシーズン（"2026-autumn" の形）。放送前のシーズンは含めない
  def self.seasons_until(today, years:)
    current_index = (today.month - 1) / 3 # 1〜3月が winter
    (today.year - years + 1..today.year).flat_map do |year|
      SEASON_NAMES_IN_ORDER.each_with_index.filter_map do |name, i|
        "#{year}-#{name}" if year < today.year || i <= current_index
      end
    end
  end

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

  private

    # 年が無ければ未設定、季節が無ければ "2025-"。季節は SEASON_NAMES_IN_ORDER のどれかだけ受け付ける
    def assign_season(year, name)
      name = nil unless SEASON_NAMES_IN_ORDER.include?(name)
      self.season = year.to_s.match?(/\A\d{4}\z/) ? "#{year}-#{name}" : nil
    end
end
