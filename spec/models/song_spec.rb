require 'rails_helper'

RSpec.describe Song, type: :model do
  describe "Spotify の連携状態のスコープ" do
    let(:artist) { create(:artist) }
    let!(:linked) { Song.create!(title: "連携済み", artist: artist).tap { |s| s.platform_links.create!(platform: :spotify, platform_track_id: "t1") } }
    let!(:untried) { Song.create!(title: "未試行", artist: artist) }
    let!(:not_found) do
      Song.create!(title: "見つからない", artist: artist).tap do |s|
        s.platform_link_attempts.create!(platform: :spotify, attempts_count: 1, last_attempted_at: Time.current, next_attempt_at: 1.day.from_now)
      end
    end

    it "spotify_unlinked は Spotify に紐づいていない曲" do
      expect(described_class.spotify_unlinked).to contain_exactly(untried, not_found)
    end

    it "spotify_untried はまだ照合していない曲" do
      expect(described_class.spotify_untried).to contain_exactly(untried)
    end

    it "spotify_not_found は照合したが見つからなかった曲" do
      expect(described_class.spotify_not_found).to contain_exactly(not_found)
    end
  end

  describe "#spotify_url" do
    let(:song) { Song.create!(title: "曲", artist: create(:artist)) }

    before do
      song.platform_links.create!(platform: :apple_music, platform_track_id: "apple1")
      song.platform_links.create!(platform: :spotify, platform_track_id: "spotify1")
    end

    it "Spotify のトラックの URL を返す" do
      expect(Song.find(song.id).spotify_url).to eq("https://open.spotify.com/track/spotify1")
    end

    it "platform_links を読み込み済みならクエリを発行しない" do
      loaded = Song.includes(:platform_links).find(song.id)
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(loaded.spotify_url).to eq("https://open.spotify.com/track/spotify1")
      end
      expect(queries).to be_empty
    end
  end
end
