class Artist < ApplicationRecord
  belongs_to :anime, optional: true
  has_many :songs, dependent: :restrict_with_error
  has_many :from_relations, class_name: "ArtistRelation", foreign_key: :from_artist_id, dependent: :destroy, inverse_of: :from_artist
  has_many :to_relations, class_name: "ArtistRelation", foreign_key: :to_artist_id, dependent: :destroy, inverse_of: :to_artist

  enum :artist_type, { person: 0, unit: 1, character: 2 }

  validates :name, presence: true
  validates :artist_type, presence: true
  validates :anime_id, presence: true, if: :character?
end
