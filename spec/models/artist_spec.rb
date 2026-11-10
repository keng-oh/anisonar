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
      unit = create(:artist, artist_type: :unit, created_by_user: ai_bot)
      ArtistRelation.create!(from_artist: orphan, to_artist: unit, relation_type: :member_of)

      expect(described_class.orphans).to be_empty
    end
  end

  describe "連名（joint）" do
    it "Spotify ID を持てない" do
      joint = build(:artist, artist_type: :joint, spotify_artist_id: "x")

      expect(joint).not_to be_valid
      expect(joint.errors[:spotify_artist_id]).to be_present
    end

    it "credited_in でメンバーと参加した連名をたどれる" do
      member = create(:artist, name: "鈴木このみ")
      joint = create(:artist, name: "鈴木このみ feat. Ashnikko", artist_type: :joint)
      joint.credit_member_relations.create!(from_artist: member)

      expect(joint.credit_members).to contain_exactly(member)
      expect(member.joint_credits).to contain_exactly(joint)
    end

    it "unsplit_joint_candidates は、名前が連名の形でまだ joint でもユニットでもないもの" do
      unsplit = create(:artist, name: "春奈るな×河野マリナ")
      create(:artist, name: "鈴木このみ feat. Ashnikko", artist_type: :joint)
      create(:artist, name: "fripSide")
      create(:artist, name: "MYTH & ROID", artist_type: :unit)

      expect(described_class.unsplit_joint_candidates).to contain_exactly(unsplit)
    end
  end
end

RSpec.describe Artist, "関係" do
  let(:anime) { create(:anime) }
  let(:actor) { create(:artist, artist_type: :person) }
  let(:singer) { create(:artist, artist_type: :person) }
  let(:character) { create(:artist, artist_type: :character, anime: anime) }
  let(:unit) { create(:artist, artist_type: :unit) }

  before do
    ArtistRelation.create!(from_artist: actor, to_artist: character, relation_type: :voice_of)
    ArtistRelation.create!(from_artist: character, to_artist: unit, relation_type: :member_of)
  end

  it "voice_of の両側と member_of の両側をたどれる" do
    expect(actor.voiced_characters).to contain_exactly(character)
    expect(character.voice_actors).to contain_exactly(actor)
    expect(character.units).to contain_exactly(unit)
    expect(unit.unit_members).to contain_exactly(character)
  end

  it "voice_actors_only は voice_of を持つ person だけ" do
    expect(described_class.voice_actors_only).to contain_exactly(actor)
    expect(described_class.voice_actors_only).not_to include(singer, character)
  end
end
