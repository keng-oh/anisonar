class Anime < ApplicationRecord
  belongs_to :anime_series, optional: true
  has_many :anime_songs, dependent: :destroy
  has_many :songs, through: :anime_songs
  has_many :artists, foreign_key: :anime_id, dependent: :nullify, inverse_of: :anime

  enum :media_type, { tv: 0, movie: 1, ova: 2, ona: 3, special: 4 }
  enum :status, { airing: 0, finished: 1 }

  validates :title, presence: true
  validates :media_type, presence: true
  validates :annict_id, uniqueness: { allow_nil: true }

  scope :by_season, ->(season) { where(season:) }
  scope :airing, -> { where(status: :airing) }
  scope :search, ->(q) { where("title ILIKE :q OR title_en ILIKE :q", q: "%#{sanitize_sql_like(q)}%") }
end
