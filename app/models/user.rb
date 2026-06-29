class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :reviews, dependent: :destroy

  enum :role, { general: 0, reviewer: 1, admin: 2, ai: 3 }

  AI_USER_EMAIL = "ai@anisonar.internal".freeze

  def self.ai_bot
    find_by!(email: AI_USER_EMAIL)
  end

  def review_weight
    reviewer? || admin? ? 3 : 1
  end

  def admin?
    role == "admin"
  end

  ROLE_LABELS = { "general" => "一般", "reviewer" => "レビュアー", "admin" => "管理者", "ai" => "AI" }.freeze

  def role_label
    ROLE_LABELS.fetch(role, role)
  end
end
