class ArtistRelation < ApplicationRecord
  belongs_to :from_artist, class_name: "Artist"
  belongs_to :to_artist, class_name: "Artist"

  # credited_in: メンバー → 連名のクレジット（「鈴木このみ」→「鈴木このみ feat. Ashnikko」）
  enum :relation_type, { member_of: 0, voice_of: 1, credited_in: 2 }

  validates :relation_type, presence: true
  validates :from_artist_id, uniqueness: { scope: [ :to_artist_id, :relation_type ] }
end
