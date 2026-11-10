require "rails_helper"

RSpec.describe ArtistRelation do
  let(:anime) { create(:anime) }
  let(:person) { create(:artist, artist_type: :person) }
  let(:character) { create(:artist, artist_type: :character, anime: anime) }
  let(:unit) { create(:artist, artist_type: :unit) }
  let(:joint) { create(:artist, artist_type: :joint) }

  def relation(from, to, type) = described_class.new(from_artist: from, to_artist: to, relation_type: type)

  describe "voice_of" do
    it { expect(relation(person, character, :voice_of)).to be_valid }

    it "from が person でないと保存できない" do
      r = relation(unit, character, :voice_of)
      expect(r).not_to be_valid
      expect(r.errors.full_messages.first).to include("声優")
    end

    it "to が character でないと保存できない" do
      expect(relation(person, unit, :voice_of)).not_to be_valid
    end
  end

  describe "member_of" do
    it "person / character から unit へは保存できる" do
      expect(relation(person, unit, :member_of)).to be_valid
      expect(relation(character, unit, :member_of)).to be_valid
    end

    it "to が unit でないと保存できない" do
      expect(relation(person, character, :member_of)).not_to be_valid
    end

    it "from が person / character でないと保存できない" do
      expect(relation(joint, unit, :member_of)).not_to be_valid
    end
  end

  it "自分自身との関係は保存できず、理由が日本語で出る" do
    r = relation(unit, unit, :member_of)
    expect(r).not_to be_valid
    expect(r.errors.full_messages).to eq [ "自分自身との関係は作れません" ]
  end

  it "credited_in は従来どおり種別を問わず保存できる" do
    expect(relation(person, joint, :credited_in)).to be_valid
    expect(relation(unit, joint, :credited_in)).to be_valid
  end
end
