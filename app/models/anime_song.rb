class AnimeSong < ApplicationRecord
  belongs_to :anime
  belongs_to :song

  validates :song_type, presence: true
  validates :anime_id, uniqueness: { scope: :song_id }
end
