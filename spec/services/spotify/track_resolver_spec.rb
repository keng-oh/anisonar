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

  # 部分一致でメンバー1人のトラックが選ばれても、連名のレコードにその人の ID を入れない
  it "連名のアーティストには ID を補完しない（曲の紐づけは行う）" do
    joint = create(:artist, name: "アクア（雨宮天）、めぐみん（高橋李依）")
    song = Song.create!(title: "ちいさな冒険者", artist: joint)
    allow(client).to receive(:search_track)
      .and_return([ { "id" => "t2", "name" => "ちいさな冒険者", "artists" => [ { "id" => "aqua", "name" => "雨宮天" } ] } ])

    link = described_class.call(song: song, client: client)

    expect(link.platform_track_id).to eq("t2")
    expect(joint.reload.spotify_artist_id).to be_nil
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
      allow(client).to receive(:search_track).with(%(track:"ちいさな冒険者" artist:"アクア（雨宮天）"), limit: 10).and_return([ solo, both ])

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
