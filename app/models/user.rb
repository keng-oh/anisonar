class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # 1 は廃止したレビュアー権限（再利用しない）
  enum :role, { general: 0, admin: 2, ai: 3 }

  AI_USER_EMAIL = "ai@anisonar.internal".freeze

  def self.ai_bot
    find_by!(email: AI_USER_EMAIL)
  end

  def admin?
    role == "admin"
  end

  ROLE_LABELS = { "general" => "一般", "admin" => "管理者", "ai" => "AI" }.freeze

  def role_label
    ROLE_LABELS.fetch(role, role)
  end
end
