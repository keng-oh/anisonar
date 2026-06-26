class Setting < ApplicationRecord
  # 利用可能な key を集約しておく(typo防止・grep性のため、文字列を直接使わない)
  module Keys
    ANNICT_BACKFILL_NEXT_YEAR = "annict_backfill_next_year"
  end

  validates :key, presence: true, uniqueness: true, inclusion: { in: Keys.constants.map { |c| Keys.const_get(c) } }

  def self.[](key)
    find_by(key: key.to_s)&.value
  end

  def self.[]=(key, value)
    find_or_initialize_by(key: key.to_s).tap do |setting|
      setting.value = value&.to_s
      setting.save!
    end
  end
end
