class Album < ApplicationRecord
  has_many :songs, dependent: :nullify

  validates :name, presence: true
  validates :spotify_album_id, presence: true, uniqueness: true
end
