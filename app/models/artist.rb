class Artist < ApplicationRecord
  belongs_to :anime, optional: true
  has_many :songs, dependent: :restrict_with_error
  has_many :from_relations, class_name: "ArtistRelation", foreign_key: :from_artist_id, dependent: :destroy, inverse_of: :from_artist
  has_many :to_relations, class_name: "ArtistRelation", foreign_key: :to_artist_id, dependent: :destroy, inverse_of: :to_artist

  enum :artist_type, { person: 0, unit: 1, character: 2 }
  enum :status, { pending: 0, reviewing: 1, approved: 2, rejected: 3 }

  belongs_to :created_by_user, class_name: "User", optional: true
  belongs_to :updated_by_user, class_name: "User", optional: true

  validates :name, presence: true
  validates :artist_type, presence: true
  validates :anime_id, presence: true, if: :character?
  validates :spotify_artist_id, uniqueness: { allow_nil: true }

  def approve!; update!(status: :approved); end
  def reject!;  update!(status: :rejected);  end
end
