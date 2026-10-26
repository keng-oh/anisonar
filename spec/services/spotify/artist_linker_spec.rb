require 'rails_helper'

RSpec.describe Spotify::ArtistLinker do
  include ActiveJob::TestHelper

  let(:client) { instance_double(Spotify::Client, search_artist: [], search_track: [], get_track: { "artists" => [] }) }
  let(:artist) { create(:artist, name: "藍井エイル") }
  let!(:linked_song) { Song.create!(title: "IGNITE", artist: artist) }
  let!(:unlinked_song) { Song.create!(title: "INNOCENCE", artist: artist) }
  let(:eir) { { "id" => "eir", "name" => "Eir Aoi", "images" => [ { "url" => "https://i.scdn.co/eir.jpg" } ] } }

  def link(dry_run: false)
    described_class.call(artist: artist, dry_run: dry_run, client: client)
  end

  context "曲が既にSpotifyのトラックに紐づいている場合" do
    before do
      linked_song.platform_links.create!(platform: :spotify, platform_track_id: "t1")
      allow(client).to receive(:get_track).with("t1").and_return({ "artists" => [ { "id" => "eir", "name" => "Eir Aoi" } ] })
    end

    it "トラックのアーティストが検索候補にあれば、それを紐づけて未連携の曲を再照合する" do
      allow(client).to receive(:search_artist).with("藍井エイル", limit: 5).and_return([ eir ])

      result = nil
      expect { result = link }.to have_enqueued_job(SpotifyTrackResolveJob).with(unlinked_song.id).exactly(:once)

      expect(result.status).to eq(:linked)
      expect(result.source).to eq(:track)
      expect(artist.reload.spotify_artist_id).to eq("eir")
      expect(artist.image_url).to eq("https://i.scdn.co/eir.jpg")
    end

    # 声優本人のレコードに、キャラ名義のアーティストIDを入れないため
    it "トラックのアーティストが検索候補になく名前も違えば、トラックからは採用しない" do
      allow(client).to receive(:get_track).with("t1")
        .and_return({ "artists" => [ { "id" => "chara", "name" => "エルヴィン・スミス(CV:小野大輔)" } ] })
      allow(client).to receive(:search_artist).and_return([ { "id" => "ono", "name" => "Someone" } ])

      expect(link.status).to eq(:not_found)
      expect(artist.reload.spotify_artist_id).to be_nil
    end
  end

  it "紐づいた曲が無ければアーティスト名の検索と曲の検証で紐づける" do
    allow(client).to receive(:search_artist).and_return([ eir ])
    allow(client).to receive(:search_track).with(%(track:"IGNITE" artist:"Eir Aoi"), limit: 10)
      .and_return([ { "name" => "IGNITE", "artists" => [ { "id" => "eir", "name" => "Eir Aoi" } ] } ])

    result = link
    expect(result.status).to eq(:linked)
    expect(result.source).to eq(:search)
    expect(artist.reload.spotify_artist_id).to eq("eir")
  end

  it "そのIDを別のアーティストが使っていれば紐づけず、重複疑いとして返す" do
    other = create(:artist, name: "Eir Aoi", spotify_artist_id: "eir")
    allow(client).to receive(:search_artist).and_return([ eir ])
    allow(client).to receive(:search_track)
      .and_return([ { "name" => "IGNITE", "artists" => [ { "id" => "eir", "name" => "Eir Aoi" } ] } ])

    result = link
    expect(result.status).to eq(:conflict)
    expect(result.conflict).to eq(other)
    expect(artist.reload.spotify_artist_id).to be_nil
  end

  it "DRY_RUNなら保存もジョブ投入もしない" do
    allow(client).to receive(:search_artist).and_return([ { "id" => "k", "name" => "藍井エイル" } ])

    expect { expect(link(dry_run: true).status).to eq(:linked) }.not_to have_enqueued_job(SpotifyTrackResolveJob)
    expect(artist.reload.spotify_artist_id).to be_nil
  end
end
