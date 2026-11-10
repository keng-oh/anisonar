require 'rails_helper'

RSpec.describe DataChecks::SpotifyNotFoundHeavyAnimes do
  let(:anime) { create(:anime) }

  def add_song(target, state)
    song = create(:song)
    target.is_a?(Anime) ? create(:anime_song, anime: target, song:) : create(:series_song, anime_series: target, song:)
    create(:platform_link, song:) if state == :linked
    create(:platform_link_attempt, song:) if state == :not_found
    song
  end

  it "照合済み 3 曲のうち半分以上（2 曲）が見つからなければ拾う" do
    add_song(anime, :linked)
    2.times { add_song(anime, :not_found) }

    findings = described_class.call
    expect(findings.map(&:record)).to eq([ anime ])
    expect(findings.first.detail).to eq("3 曲中 2 曲が見つからない")
  end

  it "半分に満たなければ拾わない（4 曲中 1 曲）" do
    3.times { add_song(anime, :linked) }
    add_song(anime, :not_found)

    expect(described_class.call).to be_empty
  end

  it "ちょうど半分（4 曲中 2 曲）は拾う" do
    2.times { add_song(anime, :linked) }
    2.times { add_song(anime, :not_found) }

    expect(described_class.call.map(&:record)).to eq([ anime ])
  end

  it "照合済みが 2 曲以下なら拾わない" do
    2.times { add_song(anime, :not_found) }

    expect(described_class.call).to be_empty
  end

  it "未照合の曲は分母に数えない" do
    add_song(anime, :linked)
    2.times { add_song(anime, :not_found) }
    10.times { add_song(anime, :untried) }

    expect(described_class.call.map(&:record)).to eq([ anime ])
  end

  it "シリーズ経由でも拾う" do
    series = create(:anime_series)
    3.times { add_song(series, :not_found) }

    expect(described_class.call.map(&:record)).to eq([ series ])
  end
end
