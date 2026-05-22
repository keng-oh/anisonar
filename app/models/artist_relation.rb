class ArtistRelation < ApplicationRecord
  belongs_to :from_artist, class_name: "Artist"
  belongs_to :to_artist, class_name: "Artist"

  enum :relation_type, { member_of: 0, voice_of: 1 }

  validates :relation_type, presence: true
  validates :from_artist_id, uniqueness: { scope: [ :to_artist_id, :relation_type ] }
end
