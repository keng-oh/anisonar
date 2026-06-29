class Song < ApplicationRecord
  belongs_to :artist
  belongs_to :created_by_user, class_name: "User", optional: true
  belongs_to :updated_by_user, class_name: "User", optional: true
  has_many :anime_songs, dependent: :destroy
  has_many :animes, through: :anime_songs
  has_many :series_songs, dependent: :destroy
  has_many :anime_series, through: :series_songs
  has_many :platform_links, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :title, presence: true

  scope :search, ->(q) { joins(:artist).where("songs.title ILIKE :q OR artists.name ILIKE :q", q: "%#{sanitize_sql_like(q)}%") }

  def spotify_link
    platform_links.find_by(platform: :spotify)
  end

  def spotify_url
    link = spotify_link
    "https://open.spotify.com/track/#{link.platform_track_id}" if link
  end
end
