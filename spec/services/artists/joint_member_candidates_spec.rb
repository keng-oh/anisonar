require 'rails_helper'

RSpec.describe Artists::JointMemberCandidates do
  def candidates(name)
    described_class.call(artist: create(:artist, name: name))
  end

  it "既存のアーティストに一致する断片は、そのアーティストを候補にする" do
    konomi = create(:artist, name: "鈴木このみ")

    result = candidates("鈴木このみ feat. Ashnikko")

    expect(result.map(&:name)).to eq [ "鈴木このみ", "Ashnikko" ]
    expect(result.first.artist).to eq konomi
    expect(result.last.artist).to be_nil
    expect(result.last.artist_type).to eq "person"
  end

  it "隣り合う断片をつないだ表記が既存のアーティストなら、分けずに候補にする" do
    myth = create(:artist, name: "MYTH & ROID", artist_type: :unit)

    result = candidates("MYTH & ROID feat. TK（凛として時雨）")

    expect(result.map(&:name)).to eq [ "MYTH & ROID", "TK（凛として時雨）" ]
    expect(result.first.artist).to eq myth
  end

  it "「名前（声優名）」の形は、キャラクターとして連名の曲のアニメを初期値にする" do
    anime = create(:anime)
    joint = create(:artist, name: "アクア（雨宮天）、めぐみん（高橋李依）")
    Song.create!(title: "ちいさな冒険者", artist: joint).anime_songs.create!(anime: anime, song_type: :ed)

    result = described_class.call(artist: joint)

    expect(result.map(&:artist_type)).to eq %w[character character]
    expect(result.map(&:anime_id)).to eq [ anime.id, anime.id ]
  end

  it "分けられない名前なら空配列" do
    expect(candidates("fripSide")).to eq []
  end
end
