class PlatformLink < ApplicationRecord
  belongs_to :song

  enum :platform, { spotify: 0, amazon_music: 1, apple_music: 2 }

  validates :platform, presence: true
  validates :platform_track_id, presence: true
  validates :platform, uniqueness: { scope: :song_id }
end
