require 'rails_helper'

RSpec.describe SpotifyTrackResolveJob do
  include ActiveSupport::Testing::TimeHelpers

  let(:client) { instance_double(Spotify::Client, search_track: []) }
  let(:artist) { create(:artist, name: "藍井エイル", spotify_artist_id: "eir") }
  let(:song) { Song.create!(title: "IGNITE", artist: artist) }
  let(:track) { { "id" => "t1", "name" => "IGNITE", "artists" => [ { "id" => "eir", "name" => "Eir Aoi" } ] } }

  before { allow(Spotify::Client).to receive(:new).and_return(client) }

  it "見つかれば紐づけ、見つからなかった記録を消す" do
    song.platform_link_attempts.create!(platform: :spotify, attempts_count: 2, last_attempted_at: 1.week.ago, next_attempt_at: 1.minute.ago)
    allow(client).to receive(:search_track).and_return([ track ])

    described_class.perform_now(song.id)

    expect(song.spotify_link.platform_track_id).to eq("t1")
    expect(song.platform_link_attempts.reload).to be_empty
  end

  it "見つからなければ、回数を数えて次に照合する時期を1日後にする" do
    freeze_time do
      described_class.perform_now(song.id)

      attempt = song.platform_link_attempts.spotify.sole
      expect(attempt.attempts_count).to eq(1)
      expect(attempt.last_attempted_at).to eq(Time.current)
      expect(attempt.next_attempt_at).to eq(1.day.from_now)
    end
  end

  it "見つからない回数が増えるほど間隔を空け、最後の間隔を以降も使う" do
    freeze_time do
      [ 1.day, 1.week, 1.month, 1.month ].each do |interval|
        described_class.perform_now(song.id)
        expect(song.platform_link_attempts.spotify.sole.next_attempt_at).to eq(Time.current + interval)
      end
    end
  end

  it "API のエラーは見つからない扱いにせず、記録を進めない" do
    allow(client).to receive(:search_track).and_raise(Spotify::Client::Error, "HTTP 503")

    expect { described_class.perform_now(song.id) }.not_to raise_error
    expect(song.platform_link_attempts).to be_empty
  end

  it "曲が削除されていれば何もしない" do
    expect { described_class.perform_now(0) }.not_to raise_error
  end
end
