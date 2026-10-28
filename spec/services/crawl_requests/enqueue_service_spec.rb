require 'rails_helper'

RSpec.describe CrawlRequests::EnqueueService do
  it "URL が無いアニメも依頼する" do
    anime = create(:anime, wikipedia_url: nil, official_site_url: nil)

    created = described_class.call(animes: [ anime ])

    expect(created.map(&:anime)).to eq [ anime ]
    expect(created.first).to be_pending
  end

  it "シリーズ所属アニメはシリーズ単位で1件にまとめる" do
    series = create(:anime_series)
    first = create(:anime, anime_series: series)
    second = create(:anime, anime_series: series)

    created = described_class.call(animes: [ first, second ])

    expect(created.size).to eq 1
    expect(created.first.anime_series).to eq series
  end

  it "依頼済みのアニメ・シリーズは状態を問わず追加しない" do
    failed = create(:anime).tap { |a| create(:crawl_request, anime: a, status: :failed) }
    series = create(:anime_series).tap { |s| create(:crawl_request, :for_series, anime_series: s, status: :done) }
    in_series = create(:anime, anime_series: series)
    fresh = create(:anime)

    created = described_class.call(animes: [ failed, in_series, fresh ])

    expect(created.map(&:anime)).to eq [ fresh ]
  end

  it "上限の件数で止める" do
    animes = create_list(:anime, 3)

    expect(described_class.call(animes: animes, limit: 2).size).to eq 2
  end
end
