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

  describe ".by_song_type" do
    let!(:via_anime) { create(:anime_song, song_type: :ed).song }
    let!(:via_series) { create(:series_song, song_type: :ed).song }
    let!(:other) { create(:anime_song, song_type: :op).song }

    it "アニメ経由・シリーズ経由のどちらの種別でも出て、別の種別は出ない" do
      expect(described_class.by_song_type("ed")).to contain_exactly(via_anime, via_series)
    end
  end

  describe ".by_anime_title" do
    let(:series) { create(:anime_series, name: "魔法の旅シリーズ") }
    let!(:by_title) { create(:anime_song, anime: create(:anime, title: "星空ロケット")).song }
    let!(:by_title_en) { create(:anime_song, anime: create(:anime, title: "別名", title_en: "Starry Rocket")).song }
    let!(:by_series_name) { create(:series_song, anime_series: series).song }
    let!(:by_series_member) do
      member_series = create(:anime_series, name: "無関係")
      create(:anime, title: "海辺の物語", anime_series: member_series)
      create(:series_song, anime_series: member_series).song
    end
    let!(:unrelated) { create(:anime_song, anime: create(:anime, title: "まったく別")).song }

    it "アニメのタイトル・英語タイトルで出る" do
      expect(described_class.by_anime_title("星空")).to contain_exactly(by_title)
      expect(described_class.by_anime_title("starry")).to contain_exactly(by_title_en)
    end

    it "紐づいたシリーズの名前で出る" do
      expect(described_class.by_anime_title("魔法の旅")).to contain_exactly(by_series_name)
    end

    it "紐づいたシリーズに属するアニメのタイトルで出る" do
      expect(described_class.by_anime_title("海辺")).to contain_exactly(by_series_member)
    end

    it "% や _ をワイルドカードとして扱わない" do
      expect(described_class.by_anime_title("%")).to be_empty
      expect(described_class.by_anime_title("星_ロケット")).to be_empty
    end

    it "search と併用できる" do
      expect(described_class.search("楽曲").by_anime_title("星空")).to contain_exactly(by_title)
    end
  end

  describe ".order_by_anime_popularity" do
    it "最も人気のアニメ（シリーズ経由を含む）で並べ、紐づきの無い曲は最後" do
      low = create(:anime_song, anime: create(:anime, watchers_count: 10)).song
      high = create(:anime_song, anime: create(:anime, watchers_count: 500)).song
      series = create(:anime_series)
      create(:anime, anime_series: series, watchers_count: 100)
      via_series = create(:series_song, anime_series: series).song
      none = create(:song)

      expect(described_class.order_by_anime_popularity).to eq([ high, via_series, low, none ])
    end
  end
end
