require 'rails_helper'

RSpec.describe Artist, type: :model do
  subject(:artist) { build(:artist) }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to have_many(:songs) }

  describe ".orphans" do
    let!(:ai_bot) { create(:user, email: User::AI_USER_EMAIL) }

    it "AIボットが作成した、曲に紐づかないアーティストを返す" do
      orphan = create(:artist, created_by_user: ai_bot)

      expect(described_class.orphans).to contain_exactly(orphan)
    end

    it "曲に紐づいているアーティストは対象外" do
      artist = create(:artist, created_by_user: ai_bot)
      Song.create!(title: "曲A", artist: artist)

      expect(described_class.orphans).to be_empty
    end

    # 手動で登録したアーティストを削除対象に巻き込まないことを保証する
    it "AIボット以外が作成したアーティストは対象外" do
      human = create(:user)
      create(:artist, created_by_user: human)
      create(:artist, created_by_user: nil)

      expect(described_class.orphans).to be_empty
    end

    it "ArtistRelationを持つアーティストは対象外" do
      orphan = create(:artist, created_by_user: ai_bot)
      member = create(:artist, created_by_user: ai_bot)
      ArtistRelation.create!(from_artist: orphan, to_artist: member, relation_type: :member_of)

      expect(described_class.orphans).to be_empty
    end
  end
end
