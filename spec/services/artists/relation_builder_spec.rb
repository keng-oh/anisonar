require "rails_helper"

RSpec.describe Artists::RelationBuilder do
  let(:user) { create(:user, :admin) }

  it "artist_id 指定ならそのアーティストを返す" do
    artist = create(:artist)
    expect(described_class.resolve(artist_id: artist.id, user: user)).to eq artist
  end

  it "同じ正規化名の既存があればそれを使う" do
    existing = create(:artist, name: "ＭＹＴＨ & ＲＯＩＤ", artist_type: :unit)
    expect { described_class.resolve(name: "MYTH & ROID", artist_type: "unit", user: user) }.not_to change(Artist, :count)
    expect(described_class.resolve(name: "MYTH & ROID", artist_type: "unit", user: user)).to eq existing
  end

  it "同じ正規化名が複数あれば、種別が合うものを優先する" do
    create(:artist, name: "Same Name", artist_type: :person)
    unit = create(:artist, name: "Same Name", artist_type: :unit)
    expect(described_class.resolve(name: "Same Name", artist_type: "unit", user: user)).to eq unit
  end

  it "無ければ作成者つきで作る" do
    artist = described_class.resolve(name: "新しい人", artist_type: "person", user: user)
    expect(artist).to be_persisted
    expect(artist.created_by_user).to eq user
    expect(artist).to be_person
  end

  it "character は所属アニメ付きで作る" do
    anime = create(:anime)
    artist = described_class.resolve(name: "後藤ひとり", artist_type: "character", anime_id: anime.id, user: user)
    expect(artist.anime).to eq anime
  end
end
