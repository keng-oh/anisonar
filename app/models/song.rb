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

  enum :status, { pending: 0, reviewing: 1, approved: 2, rejected: 3 }

  validates :title, presence: true
  validates :song_type, presence: true

  scope :approved, -> { where(status: :approved) }
  scope :pending_review, -> { where(status: [ :pending, :reviewing ]) }

  def spotify_link
    platform_links.find_by(platform: :spotify)
  end

  def approve!
    update!(status: :approved)
  end

  def reject!
    update!(status: :rejected)
  end
end
