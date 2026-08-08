require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it { is_expected.to be_valid }
  it { is_expected.to have_many(:reviews) }

  describe "#review_weight" do
    it "returns 1 for general user" do
      expect(build(:user).review_weight).to eq(1)
    end

    it "returns 3 for reviewer" do
      expect(build(:user, :reviewer).review_weight).to eq(3)
    end

    it "returns 3 for admin" do
      expect(build(:user, :admin).review_weight).to eq(3)
    end
  end
end
