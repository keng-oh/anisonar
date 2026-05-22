class AnimeSeries < ApplicationRecord
  has_many :animes, dependent: :nullify

  validates :name, presence: true
end
