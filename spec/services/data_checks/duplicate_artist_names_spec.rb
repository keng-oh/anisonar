require 'rails_helper'

RSpec.describe DataChecks::DuplicateArtistNames do
  it "正規化した名前が同じアーティストを拾う" do
    a = create(:artist, name: "梶浦由記")
    b = create(:artist, name: "梶浦 由記")
    create(:artist, name: "別の人")

    expect(described_class.call.map(&:record)).to contain_exactly(a, b)
  end

  it "同じ anime_id のキャラクターの重複を拾う" do
    anime = create(:anime)
    a = create(:artist, name: "後藤ひとり", artist_type: :character, anime:)
    b = create(:artist, name: "後藤ひとり", artist_type: :character, anime:)

    expect(described_class.call.map(&:record)).to contain_exactly(a, b)
  end

  it "anime_id が違うキャラクターは拾わない" do
    create(:artist, name: "ひとり", artist_type: :character, anime: create(:anime))
    create(:artist, name: "ひとり", artist_type: :character, anime: create(:anime))

    expect(described_class.call).to be_empty
  end
end
