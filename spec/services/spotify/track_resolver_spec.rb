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
end
