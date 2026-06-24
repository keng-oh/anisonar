class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :reviews, dependent: :destroy

  enum :role, { general: 0, reviewer: 1, admin: 2, ai: 3 }

  validates :trusted_count, numericality: { greater_than_or_equal_to: 0 }

  AI_USER_EMAIL = "ai@anisonar.internal".freeze

  def self.ai_bot
    find_by!(email: AI_USER_EMAIL)
  end

  def review_weight
    return 3 if reviewer? || admin?
    return 2 if trusted_count >= 10
    1
  end

  def admin?
    role == "admin"
  end
end
