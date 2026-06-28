class SeriesSong < ApplicationRecord
  belongs_to :anime_series
  belongs_to :song

  enum :song_type, { op: 0, ed: 1, insert: 2, image: 3, soundtrack: 4, other: 5 }, prefix: :song

  validates :song_type, presence: true
end
