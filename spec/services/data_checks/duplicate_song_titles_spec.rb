require 'rails_helper'

RSpec.describe DataChecks::DuplicateSongTitles do
  let(:anime) { create(:anime) }

  it "同じアニメの同名・別アーティストの曲を、両方拾う" do
    a = create(:song, title: "青春コンプレックス", artist: create(:artist, name: "結束バンド"))
    b = create(:song, title: "青春コンプレックス", artist: create(:artist, name: "喜多郁代"))
    create(:anime_song, anime:, song: a)
    create(:anime_song, anime:, song: b)

    findings = described_class.call
    expect(findings.map(&:record)).to contain_exactly(a, b)
    expect(findings.find { |f| f.record == a }.detail).to include("喜多郁代", anime.title)
  end

  it "表記の揺れ（空白・全角半角・大文字小文字）を吸収する" do
    a = create(:song, title: "Hello World")
    b = create(:song, title: "ＨＥＬＬＯ　ＷＯＲＬＤ")
    create(:anime_song, anime:, song: a)
    create(:anime_song, anime:, song: b)

    expect(described_class.call.map(&:record)).to contain_exactly(a, b)
  end

  it "別のアニメの同名曲は拾わない" do
    create(:anime_song, anime:, song: create(:song, title: "同じ曲"))
    create(:anime_song, anime: create(:anime), song: create(:song, title: "同じ曲"))

    expect(described_class.call).to be_empty
  end

  it "同じ曲が同じアニメに複数の種別で紐づいていても拾わない" do
    song = create(:song, title: "一曲")
    create(:anime_song, anime:, song:)
    create(:series_song, song:)

    expect(described_class.call).to be_empty
  end

  it "シリーズ経由でも拾う" do
    series = create(:anime_series)
    a = create(:song, title: "同じ曲")
    b = create(:song, title: "同じ曲")
    create(:series_song, anime_series: series, song: a)
    create(:series_song, anime_series: series, song: b)

    findings = described_class.call
    expect(findings.map(&:record)).to contain_exactly(a, b)
    expect(findings.first.detail).to include(series.name)
  end
end
