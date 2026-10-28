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

  describe "放送年" do
    it "作品の season の年を shelf_year に付ける。season が年だけでも読む" do
      spring = spotify_song("春の曲")
      year_only = spotify_song("年だけの曲")
      no_season = spotify_song("season なしの曲")
      AnimeSong.create!(anime: anime(30, season: "2020-spring"), song: spring, song_type: :op)
      AnimeSong.create!(anime: anime(20, season: "2018-"), song: year_only, song_type: :op)
      AnimeSong.create!(anime: anime(10, season: nil), song: no_season, song_type: :op)

      expect(described_class.call.map { |song| [ song.title, song.shelf_year ] })
        .to eq([ [ "春の曲", 2020 ], [ "年だけの曲", 2018 ], [ "season なしの曲", nil ] ])
    end

    it "year: でその年の曲だけを人気順に返す。season の無い作品の曲は出ない" do
      popular_2020 = spotify_song("2020 の人気曲")
      minor_2020 = spotify_song("2020 のマイナー曲")
      song_2021 = spotify_song("2021 の曲")
      no_season = spotify_song("season なしの曲")
      AnimeSong.create!(anime: anime(10, season: "2020-winter"), song: minor_2020, song_type: :ed)
      AnimeSong.create!(anime: anime(900, season: "2020-autumn"), song: popular_2020, song_type: :op)
      AnimeSong.create!(anime: anime(500, season: "2021-spring"), song: song_2021, song_type: :op)
      AnimeSong.create!(anime: anime(999, season: nil), song: no_season, song_type: :op)

      expect(described_class.call(year: 2020).to_a).to eq([ popular_2020, minor_2020 ])
      expect(described_class.call(year: 2019)).to be_empty
    end

    it "曲の年は、最も人気の作品の年になる" do
      song = spotify_song("リメイクでも使われた曲")
      AnimeSong.create!(anime: anime(100, season: "2005-spring"), song: song, song_type: :op)
      AnimeSong.create!(anime: anime(800, season: "2022-spring"), song: song, song_type: :op)

      expect(described_class.call(year: 2022).to_a).to eq([ song ])
      expect(described_class.call(year: 2005)).to be_empty
    end

    it "シリーズ共通の曲は、シリーズ内で最も人気のアニメの年になる" do
      series = create(:anime_series)
      anime(50, anime_series: series, season: "2013-spring")
      anime(700, anime_series: series, season: "2016-summer")
      song = spotify_song("シリーズの ED")
      SeriesSong.create!(anime_series: series, song: song, song_type: :ed)

      expect(described_class.call(year: 2016).first).to have_attributes(id: song.id, shelf_year: 2016, shelf_popularity: 700)
      expect(described_class.call(year: 2013)).to be_empty
    end

    it ".years は棚に曲がある年を新しい順に返す" do
      AnimeSong.create!(anime: anime(10, season: "2019-spring"), song: spotify_song("2019"), song_type: :op)
      AnimeSong.create!(anime: anime(20, season: "2024-autumn"), song: spotify_song("2024 の OP"), song_type: :op)
      AnimeSong.create!(anime: anime(30, season: "2024-winter"), song: spotify_song("2024 の ED"), song_type: :ed)
      AnimeSong.create!(anime: anime(40, season: "2021-spring"), song: spotify_song("2021 の挿入歌"), song_type: :insert)
      AnimeSong.create!(anime: anime(50, season: "2022-spring"), song: Song.create!(title: "未連携", artist: artist), song_type: :op)
      AnimeSong.create!(anime: anime(60, season: nil), song: spotify_song("season なし"), song_type: :op)

      expect(described_class.years).to eq([ 2024, 2019 ])
    end
  end
end
