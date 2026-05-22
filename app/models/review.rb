class Review < ApplicationRecord
  belongs_to :song
  belongs_to :user

  enum :action, { approve: 0, reject: 1, flag: 2 }, prefix: :review

  validates :action, presence: true
  validates :weight, numericality: { greater_than: 0 }
  validates :user_id, uniqueness: { scope: :song_id }

  before_validation :set_weight_from_user

  private

  def set_weight_from_user
    self.weight ||= user&.review_weight
  end
end
