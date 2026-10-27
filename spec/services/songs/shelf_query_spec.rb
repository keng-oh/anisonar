require "rails_helper"

RSpec.describe Songs::ShelfQuery do
  let(:artist) { create(:artist) }

  def spotify_song(title)
    Song.create!(title: title, artist: artist).tap { |s| s.platform_links.create!(platform: :spotify, platform_track_id: "track-#{title}") }
  end

  def anime(watchers_count, **attrs)
    create(:anime, watchers_count: watchers_count, **attrs)
  end

  describe ".call" do
    it "Spotify に紐づいた曲だけを返す" do
      linked = spotify_song("連携済み")
      unlinked = Song.create!(title: "未連携", artist: artist)
      apple_only = Song.create!(title: "Apple Music のみ", artist: artist).tap { |s| s.platform_links.create!(platform: :apple_music, platform_track_id: "a1") }
      target = anime(10)
      [ linked, unlinked, apple_only ].each { |song| AnimeSong.create!(anime: target, song: song, song_type: :op) }

      expect(described_class.call).to contain_exactly(linked)
    end

    it "OP と ED だけを返す" do
      target = anime(10)
      op = spotify_song("OP")
      ed = spotify_song("ED")
      insert = spotify_song("挿入歌")
      series = create(:anime_series)
      series_image = spotify_song("シリーズのイメージソング")
      AnimeSong.create!(anime: target, song: op, song_type: :op)
      AnimeSong.create!(anime: target, song: ed, song_type: :ed)
      AnimeSong.create!(anime: target, song: insert, song_type: :insert)
      SeriesSong.create!(anime_series: series, song: series_image, song_type: :image)

      expect(described_class.call).to contain_exactly(op, ed)
    end

    it "アニメの watchers_count の多い順に並べる。シリーズの曲はシリーズ内で最も人気のアニメで並べる" do
      series = create(:anime_series)
      anime(50, anime_series: series)
      anime(500, anime_series: series)
      low = spotify_song("人気が低い")
      high = spotify_song("人気が高い")
      series_song = spotify_song("シリーズの OP")
      AnimeSong.create!(anime: anime(100), song: low, song_type: :op)
      AnimeSong.create!(anime: anime(1000), song: high, song_type: :ed)
      SeriesSong.create!(anime_series: series, song: series_song, song_type: :op)

      expect(described_class.call.to_a).to eq([ high, series_song, low ])
    end

    it "複数の作品で使われている曲は 1 回だけ、最も人気の作品の位置に出す" do
      series = create(:anime_series, name: "人気シリーズ")
      popular = anime(900, anime_series: series)
      shared = spotify_song("共通の曲")
      other = spotify_song("別の曲")
      AnimeSong.create!(anime: anime(10, title: "マイナー作品"), song: shared, song_type: :op)
      AnimeSong.create!(anime: anime(300, title: "中くらいの作品"), song: shared, song_type: :ed)
      SeriesSong.create!(anime_series: series, song: shared, song_type: :ed)
      AnimeSong.create!(anime: anime(500), song: other, song_type: :op)

      result = described_class.call.to_a

      expect(result).to eq([ shared, other ])
      expect(result.first).to have_attributes(
        shelf_work_title: "人気シリーズ",
        shelf_song_type: "ed",
        shelf_anime_id: nil,
        shelf_anime_series_id: series.id,
        shelf_popularity: popular.watchers_count
      )
    end

    it "表示用にアニメのタイトルと種別を付ける" do
      target = anime(10, title: "作品A")
      song = spotify_song("曲")
      AnimeSong.create!(anime: target, song: song, song_type: :op)

      expect(described_class.call.first).to have_attributes(
        shelf_work_title: "作品A", shelf_song_type: "op", shelf_anime_id: target.id, shelf_anime_series_id: nil
      )
    end

    it "ページ分けのために件数を数えられる" do
      target = anime(10)
      2.times { |i| AnimeSong.create!(anime: target, song: spotify_song("曲#{i}"), song_type: :op) }

      expect(described_class.call.count(:all)).to eq(2)
    end
  end
end
