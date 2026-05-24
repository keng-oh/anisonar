class Review < ApplicationRecord
  belongs_to :reviewable, polymorphic: true
  belongs_to :user

  enum :action, { approve: 0, reject: 1, flag: 2 }, prefix: :review

  validates :action, presence: true
  validates :weight, numericality: { greater_than: 0 }
  validates :user_id, uniqueness: { scope: [ :reviewable_type, :reviewable_id ] }

  before_validation :set_weight_from_user

  private

  def set_weight_from_user
    self.weight ||= user&.review_weight
  end
end
