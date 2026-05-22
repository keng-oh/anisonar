require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it { is_expected.to be_valid }
  it { is_expected.to have_many(:reviews) }
  it { is_expected.to validate_numericality_of(:trusted_count).is_greater_than_or_equal_to(0) }

  describe "#review_weight" do
    it "returns 1 for general user" do
      expect(build(:user).review_weight).to eq(1)
    end

    it "returns 2 for trusted user (trusted_count >= 10)" do
      expect(build(:user, :trusted).review_weight).to eq(2)
    end

    it "returns 3 for reviewer" do
      expect(build(:user, :reviewer).review_weight).to eq(3)
    end

    it "returns 3 for admin" do
      expect(build(:user, :admin).review_weight).to eq(3)
    end
  end
end
