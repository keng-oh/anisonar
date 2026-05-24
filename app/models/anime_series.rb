class AnimeSeries < ApplicationRecord
  has_many :animes, dependent: :nullify
  has_many :series_songs, dependent: :destroy
  has_many :songs, through: :series_songs

  validates :name, presence: true
end
