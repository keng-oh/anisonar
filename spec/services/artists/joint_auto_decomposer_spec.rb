require 'rails_helper'

RSpec.describe Artists::JointAutoDecomposer do
  include ActiveJob::TestHelper

  let!(:ai_bot) { create(:user, email: User::AI_USER_EMAIL, role: :ai) }
  let(:client) { instance_double(Spotify::Client, search_track: [], get_track: {}) }
  let(:anime) { create(:anime) }
  let(:joint) { create(:artist, name: "アクア（雨宮天）、めぐみん（高橋李依）") }
  let!(:song) { Song.create!(title: "ちいさな冒険者", artist: joint).tap { |s| s.anime_songs.create!(anime: anime, song_type: :ed) } }
  let(:track) do
    { "id" => "t1", "name" => "ちいさな冒険者",
      "artists" => [ { "id" => "aqua", "name" => "アクア (CV: 雨宮 天)" }, { "id" => "megumin", "name" => "めぐみん (CV: 高橋李依)" } ] }
  end

  def decompose(artist = joint, dry_run: false)
    described_class.call(artist: artist, dry_run: dry_run, client: client)
  end

  it "トラックのアーティストと断片が対応すれば、メンバーに分解して Spotify ID を付ける" do
    aqua = create(:artist, name: "アクア（雨宮天）")
    allow(client).to receive(:search_track).with("ちいさな冒険者 アクア（雨宮天）", limit: 10).and_return([ track ])

    result = decompose

    expect(result).to be_decomposed
    expect(joint.reload).to be_joint
    expect(joint.credit_members.map(&:name)).to contain_exactly("アクア（雨宮天）", "めぐみん（高橋李依）")
    expect(aqua.reload.spotify_artist_id).to eq "aqua"
    megumin = Artist.find_by(name: "めぐみん（高橋李依）")
    expect(megumin).to have_attributes(spotify_artist_id: "megumin", artist_type: "character", anime_id: anime.id, created_by_user: ai_bot)
  end

  it "曲が Spotify に紐づいていれば、検索せずにそのトラックを使う" do
    song.platform_links.create!(platform: :spotify, platform_track_id: "t1")
    allow(client).to receive(:get_track).with("t1").and_return(track)

    expect(decompose).to be_decomposed
    expect(client).not_to have_received(:search_track)
  end

  it "隣り合う断片をまとめて1人に対応させる（& がユニット名の一部の場合）" do
    joint = create(:artist, name: "MYTH & ROID feat. TK（凛として時雨）")
    Song.create!(title: "曲", artist: joint)
    allow(client).to receive(:search_track).and_return([
      { "name" => "曲", "artists" => [ { "id" => "myth", "name" => "MYTH & ROID" }, { "id" => "tk", "name" => "TK（凛として時雨）" } ] }
    ])

    result = decompose(joint)

    expect(result.members.map(&:name)).to eq [ "MYTH & ROID", "TK（凛として時雨）" ]
    expect(joint.reload.credit_members.map(&:name)).to contain_exactly("MYTH & ROID", "TK（凛として時雨）")
  end

  it "名前が違っても、その Spotify ID を持つ既存のアーティストの名前と一致すれば対応させる" do
    joint = create(:artist, name: "藍井エイル feat. 誰か")
    Song.create!(title: "曲", artist: joint)
    eir = create(:artist, name: "藍井エイル", spotify_artist_id: "eir")
    allow(client).to receive(:search_track).and_return([
      { "name" => "曲", "artists" => [ { "id" => "eir", "name" => "Eir Aoi" }, { "id" => "x", "name" => "誰か" } ] }
    ])

    expect(decompose(joint)).to be_decomposed
    expect(joint.reload.credit_members).to include(eir)
  end

  it "Spotify の並び順が違っても、断片とアーティストが同じ数なら対応させる" do
    allow(client).to receive(:search_track).and_return([ track.merge("artists" => track["artists"].reverse) ])

    expect(decompose).to be_decomposed
  end

  it "人数が違うトラック（ソロ版など）では分解しない" do
    allow(client).to receive(:search_track).and_return([ track.merge("artists" => track["artists"].first(1)) ])

    expect(decompose.status).to eq :not_found
    expect(joint.reload).to be_person
  end

  it "表記が対応しないトラックでは分解しない" do
    allow(client).to receive(:search_track).and_return([ track.merge("artists" => [ { "id" => "a", "name" => "Aqua" }, { "id" => "m", "name" => "Megumin" } ]) ])

    expect(decompose.status).to eq :not_found
  end

  it "曲名が違うトラックは使わない" do
    allow(client).to receive(:search_track).and_return([ track.merge("name" => "別の曲") ])

    expect(decompose.status).to eq :not_found
  end

  it "dry_run では保存しない" do
    allow(client).to receive(:search_track).and_return([ track ])

    result = decompose(dry_run: true)

    expect(result).to be_decomposed
    expect(result.members.map(&:spotify_name)).to eq [ "アクア (CV: 雨宮 天)", "めぐみん (CV: 高橋李依)" ]
    expect(joint.reload).to be_person
    expect(Artist.find_by(name: "めぐみん（高橋李依）")).to be_nil
  end

  it "分解済み・連名の形でない名前は何もしない" do
    expect(decompose(create(:artist, name: "fripSide")).status).to eq :skipped
    expect(decompose(create(:artist, name: "A feat. B", artist_type: :joint)).status).to eq :skipped
  end
end
