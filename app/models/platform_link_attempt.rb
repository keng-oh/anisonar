# 配信サービスで照合したが見つからなかった曲の記録。紐づいたら消す。
class PlatformLinkAttempt < ApplicationRecord
  belongs_to :song

  enum :platform, PlatformLink.platforms

  validates :platform, presence: true, uniqueness: { scope: :song_id }

  scope :due, ->(now = Time.current) { where(next_attempt_at: ..now) }
end
