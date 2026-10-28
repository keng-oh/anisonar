require 'rails_helper'

RSpec.describe CrawlRequests::BulkEnqueueService do
  let(:today) { Date.new(2026, 10, 28) }

  def anime(season:, watchers:)
    create(:anime, season: season, watchers_count: watchers)
  end

  it ":popular は未依頼のアニメを視聴者数の多い順に追加する" do
    low = anime(season: "2010-spring", watchers: 10)
    high = anime(season: "2008-autumn", watchers: 100)
    anime(season: "2009-winter", watchers: 50).tap { |a| create(:crawl_request, anime: a) }

    created = described_class.call(limit: 2, strategy: :popular, today: today)

    expect(created.map(&:anime)).to eq [ high, low ]
  end

  it ":recent は去年から今のシーズンまでの作品だけを、視聴者数の多い順に追加する（放送前は除く）" do
    old = anime(season: "2023-spring", watchers: 1000)
    last_year = anime(season: "2025-winter", watchers: 10)
    this_season = anime(season: "2026-autumn", watchers: 20)
    next_year = anime(season: "2027-winter", watchers: 500)

    created = described_class.call(limit: 10, strategy: :recent, today: today)

    expect(created.map(&:anime)).to eq [ this_season, last_year ]
    expect(created.map(&:anime)).not_to include(old, next_year)
  end
end
