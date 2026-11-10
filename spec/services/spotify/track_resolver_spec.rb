require 'rails_helper'

RSpec.describe Spotify::TrackResolver do
  let(:client) { instance_double(Spotify::Client) }

  it "Spotify ID の無いアーティストに、トラックのアーティストの ID を補完する" do
    artist = create(:artist, name: "藍井エイル")
    song = Song.create!(title: "IGNITE", artist: artist)
    allow(client).to receive(:search_track)
      .and_return([ { "id" => "t1", "name" => "IGNITE", "artists" => [ { "id" => "eir", "name" => "藍井エイル" } ] } ])

    described_class.call(song: song, client: client)

    expect(artist.reload.spotify_artist_id).to eq("eir")
  end

  # 部分一致をやめたので、メンバー1人のトラック（雨宮天名義）には紐づけず、ID も補完しない
  it "連名の形のアーティストは、メンバー単独のトラックに紐づけず、ID も補完しない" do
    joint = create(:artist, name: "アクア（雨宮天）、めぐみん（高橋李依）")
    song = Song.create!(title: "ちいさな冒険者", artist: joint)
    allow(client).to receive(:search_track)
      .and_return([ { "id" => "t2", "name" => "ちいさな冒険者", "artists" => [ { "id" => "aqua", "name" => "雨宮天" } ] } ])

    expect(described_class.call(song: song, client: client)).to be_nil
    expect(joint.reload.spotify_artist_id).to be_nil
  end

  def track(id, title, *artists)
    { "id" => id, "name" => title, "artists" => artists.map { |i, n| { "id" => i, "name" => n } } }
  end

  context "本人名義" do
    it "表記違い（CV:・空白・全角半角）でも紐づき、ID が付く。検索は絞り込まない" do
      artist = create(:artist, name: "めぐみん（高橋李依）", artist_type: :character, anime: create(:anime))
      song = Song.create!(title: "曲A", artist: artist)
      allow(client).to receive(:search_track).with("曲A めぐみん（高橋李依）", limit: 10)
        .and_return([ track("t1", "曲A", [ "meg", "めぐみん (CV: 高橋李依)" ]) ])

      link = described_class.call(song: song, client: client)

      expect(link.platform_track_id).to eq("t1")
      expect(artist.reload.spotify_artist_id).to eq("meg")
    end

    it "曲名が違うトラックには紐づかない" do
      artist = create(:artist, name: "藍井エイル")
      song = Song.create!(title: "曲A", artist: artist)
      allow(client).to receive(:search_track).and_return([ track("t1", "別の曲", [ "eir", "藍井エイル" ]) ])

      expect(described_class.call(song: song, client: client)).to be_nil
    end

    it "かっこの外と丸ごと一致すれば紐づき、ユニットに ID が付く" do
      artist = create(:artist, name: "TrySail（麻倉もも、雨宮天、夏川椎菜）", artist_type: :unit)
      song = Song.create!(title: "曲A", artist: artist)
      allow(client).to receive(:search_track).and_return([ track("t1", "曲A", [ "ts", "TrySail" ]) ])

      expect(described_class.call(song: song, client: client).platform_track_id).to eq("t1")
      expect(artist.reload.spotify_artist_id).to eq("ts")
    end

    it "部分一致（fripSide に Side）では紐づかず、ID も付かない" do
      artist = create(:artist, name: "fripSide")
      song = Song.create!(title: "曲A", artist: artist)
      allow(client).to receive(:search_track).and_return([ track("t1", "曲A", [ "side", "Side" ]) ])

      expect(described_class.call(song: song, client: client)).to be_nil
      expect(artist.reload.spotify_artist_id).to be_nil
    end
  end

  context "声優名義" do
    let(:anime) { create(:anime) }

    it "名前のかっこの中の名前で探して紐づけ、キャラクターに ID を付けない" do
      artist = create(:artist, name: "ユイ（LiSA）", artist_type: :character, anime: anime)
      song = Song.create!(title: "一番の宝物 (Yui ver.)", artist: artist)
      allow(client).to receive(:search_track).and_return([])
      allow(client).to receive(:search_track).with("一番の宝物 (Yui ver.) LiSA", limit: 10)
        .and_return([ track("t1", "一番の宝物 (Yui ver.)", [ "lisa", "LiSA" ]) ])

      expect(described_class.call(song: song, client: client).platform_track_id).to eq("t1")
      expect(artist.reload.spotify_artist_id).to be_nil
    end

    it "本人名義の検索でも声優名義のトラックが返るとき、紐づけるがキャラクターに ID を付けない" do
      artist = create(:artist, name: "ユイ（LiSA）", artist_type: :character, anime: anime)
      song = Song.create!(title: "一番の宝物 (Yui ver.)", artist: artist)
      allow(client).to receive(:search_track)
        .and_return([ track("t1", "一番の宝物 (Yui ver.)", [ "lisa", "LiSA" ]) ])

      expect(described_class.call(song: song, client: client).platform_track_id).to eq("t1")
      expect(artist.reload.spotify_artist_id).to be_nil
    end

    it "voice_of で設定された声優の ID を持つトラックに、名前が違っても紐づける" do
      voice = create(:artist, name: "高橋李依", spotify_artist_id: "rie")
      artist = create(:artist, name: "めぐみん", artist_type: :character, anime: anime)
      ArtistRelation.create!(from_artist: voice, to_artist: artist, relation_type: :voice_of)
      song = Song.create!(title: "曲A", artist: artist)
      allow(client).to receive(:search_track).and_return([])
      allow(client).to receive(:search_track).with("曲A 高橋李依", limit: 10)
        .and_return([ track("t1", "曲A", [ "rie", "Rie Takahashi" ]) ])

      expect(described_class.call(song: song, client: client).platform_track_id).to eq("t1")
      expect(artist.reload.spotify_artist_id).to be_nil
    end
  end

  context "作品名義" do
    let(:series) { AnimeSeries.create!(name: "〈物語〉シリーズ") }
    let(:artist) { create(:artist, name: "千石撫子", artist_type: :character, anime: create(:anime)) }
    let(:song) { Song.create!(title: "曲A", artist: artist).tap { |s| s.anime_series << series } }

    it "作品名と一致する名義のトラックに紐づけ、ID は付けない" do
      allow(client).to receive(:search_track).and_return([])
      allow(client).to receive(:search_track).with("曲A 〈物語〉シリーズ", limit: 10)
        .and_return([ track("t1", "曲A", [ "mono", "物語シリーズ" ]) ])

      expect(described_class.call(song: song, client: client).platform_track_id).to eq("t1")
      expect(artist.reload.spotify_artist_id).to be_nil
    end

    it "カバー名義（歌っちゃ王）のトラックには紐づかない" do
      allow(client).to receive(:search_track).and_return([ track("t1", "曲A", [ "x", "歌っちゃ王" ]) ])

      expect(described_class.call(song: song, client: client)).to be_nil
    end
  end

  it "本人名義で見つかれば、声優・作品名義の検索をしない" do
    artist = create(:artist, name: "ユイ（LiSA）", artist_type: :character, anime: create(:anime))
    song = Song.create!(title: "曲A", artist: artist)
    allow(client).to receive(:search_track).and_return([ track("t1", "曲A", [ "yui", "ユイ（LiSA）" ]) ])

    described_class.call(song: song, client: client)

    expect(client).to have_received(:search_track).once
  end

  context "連名（joint）の曲" do
    let(:aqua) { create(:artist, name: "アクア（雨宮天）", artist_type: :character, anime: create(:anime), spotify_artist_id: "aqua") }
    let(:megumin) { create(:artist, name: "めぐみん（高橋李依）", artist_type: :character, anime: aqua.anime, spotify_artist_id: "megumin") }
    let(:joint) do
      create(:artist, name: "アクア（雨宮天）、めぐみん（高橋李依）", artist_type: :joint).tap do |j|
        [ aqua, megumin ].each { |m| j.credit_member_relations.create!(from_artist: m) }
      end
    end
    let(:song) { Song.create!(title: "ちいさな冒険者", artist: joint) }
    let(:both) { { "id" => "t1", "name" => "ちいさな冒険者", "artists" => [ { "id" => "aqua" }, { "id" => "megumin" } ] } }
    let(:solo) { { "id" => "t2", "name" => "ちいさな冒険者 (アクア ソロ ver.)", "artists" => [ { "id" => "aqua" } ] } }

    it "Spotify ID を持つメンバーの名前で検索し、メンバー全員が並ぶトラックに紐づける" do
      allow(client).to receive(:search_track).with("ちいさな冒険者 アクア（雨宮天）", limit: 10).and_return([ solo, both ])

      link = described_class.call(song: song, client: client)

      expect(link.platform_track_id).to eq("t1")
      expect(joint.reload.spotify_artist_id).to be_nil
    end

    it "メンバーの一部しか並ばないトラック（ソロ版）は選ばない" do
      allow(client).to receive(:search_track).and_return([ solo ])

      expect(described_class.call(song: song, client: client)).to be_nil
    end

    it "曲名が違うトラックは選ばない" do
      allow(client).to receive(:search_track).and_return([ both.merge("name" => "別の曲") ])

      expect(described_class.call(song: song, client: client)).to be_nil
    end

    it "Spotify ID を持つメンバーがいなければ検索しない" do
      [ aqua, megumin ].each { |m| m.update!(spotify_artist_id: nil) }
      allow(client).to receive(:search_track)

      expect(described_class.call(song: song, client: client)).to be_nil
      expect(client).not_to have_received(:search_track)
    end
  end
end
