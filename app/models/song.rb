class Song < ApplicationRecord
  belongs_to :artist
  has_many :anime_songs, dependent: :destroy
  has_many :animes, through: :anime_songs
  has_many :platform_links, dependent: :destroy
  has_many :reviews, dependent: :destroy

  enum :song_type, { op: 0, ed: 1, insert: 2, image: 3 }, prefix: :song
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
