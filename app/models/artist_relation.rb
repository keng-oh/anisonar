class ArtistRelation < ApplicationRecord
  belongs_to :from_artist, class_name: "Artist"
  belongs_to :to_artist, class_name: "Artist"

  # credited_in: メンバー → 連名のクレジット（「鈴木このみ」→「鈴木このみ feat. Ashnikko」）
  enum :relation_type, { member_of: 0, voice_of: 1, credited_in: 2 }

  validates :relation_type, presence: true
  validates :from_artist_id, uniqueness: { scope: [ :to_artist_id, :relation_type ] }
  validate :artist_types_match_relation_type

  private

    # 種別の組み合わせを検証する。credited_in は連名の分解（JointDecomposer）の運用を壊さないよう検証しない
    def artist_types_match_relation_type
      return if from_artist.nil? || to_artist.nil?

      if from_artist_id == to_artist_id
        errors.add(:base, :self_relation)
      elsif voice_of?
        errors.add(:base, :invalid_voice_of) unless from_artist.person? && to_artist.character?
      elsif member_of?
        errors.add(:base, :invalid_member_of) unless to_artist.unit? && (from_artist.person? || from_artist.character?)
      end
    end
end
