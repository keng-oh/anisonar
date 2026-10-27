class Artist < ApplicationRecord
  belongs_to :anime, optional: true
  has_many :songs, dependent: :restrict_with_error
  has_many :from_relations, class_name: "ArtistRelation", foreign_key: :from_artist_id, dependent: :destroy, inverse_of: :from_artist
  has_many :to_relations, class_name: "ArtistRelation", foreign_key: :to_artist_id, dependent: :destroy, inverse_of: :to_artist
  has_many :credit_member_relations, -> { credited_in }, class_name: "ArtistRelation", foreign_key: :to_artist_id, inverse_of: :to_artist
  has_many :credit_members, through: :credit_member_relations, source: :from_artist
  has_many :joint_credit_relations, -> { credited_in }, class_name: "ArtistRelation", foreign_key: :from_artist_id, inverse_of: :from_artist
  has_many :joint_credits, through: :joint_credit_relations, source: :to_artist

  # joint: 連名のクレジット。メンバーとは credited_in で結ぶ
  enum :artist_type, { person: 0, unit: 1, character: 2, joint: 3 }

  belongs_to :created_by_user, class_name: "User", optional: true
  belongs_to :updated_by_user, class_name: "User", optional: true

  before_validation :format_names

  validates :name, presence: true
  validates :artist_type, presence: true
  validates :anime_id, presence: true, if: :character?
  validates :spotify_artist_id, uniqueness: { allow_nil: true }
  # Spotify に連名のアーティストは存在しない。メンバーの ID を付けると、ユニーク制約のため
  # メンバー本人のレコードがその ID を取れなくなる
  validates :spotify_artist_id, absence: { message: :joint_artist }, if: :joint?

  scope :search, ->(q) { where("name ILIKE :q OR name_kana ILIKE :q", q: "%#{sanitize_sql_like(q)}%") }
  scope :unsplit_joint_candidates, -> { where.not(artist_type: :joint).where("name ~* ?", JointNameSplitter::SQL_PATTERN) }

  # 取り込みジョブの部分失敗で残った、曲に紐づかないアーティストを抽出する。
  # 手動で登録したものを巻き込まないよう、AIボットが作成したものだけを対象にする。
  scope :orphans, -> {
    where(created_by_user: User.ai_bot)
      .where.missing(:songs)
      .where.missing(:from_relations)
      .where.missing(:to_relations)
  }

  private

    # 表示値は NameFormatter で整え、照合用のキーは normalized_* に持たせる。
    # 表示は書かれた表記を尊重し、重複判定は表記揺れを無視する、という要件を両立させるため
    # （SQLではNFKC正規化ができないので、キーをカラムとして持つ必要がある）。
    def format_names
      self.name = NameFormatter.call(name)
      self.name_kana = NameFormatter.call(name_kana)
      self.normalized_name = NameNormalizer.call(name)
      self.normalized_name_kana = name_kana.presence && NameNormalizer.call(name_kana)
    end
end
