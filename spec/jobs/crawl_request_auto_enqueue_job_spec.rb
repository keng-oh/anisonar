require 'rails_helper'

RSpec.describe CrawlRequestAutoEnqueueJob do
  it "処理待ちが少なければ、最近の作品と人気の作品から補充する" do
    recent = create(:anime, season: Anime.seasons_until(Date.current, years: 1).last, watchers_count: 1)
    popular = create(:anime, season: "2005-spring", watchers_count: 9999)

    described_class.perform_now

    expect(CrawlRequest.pending.map(&:anime)).to include(recent, popular)
  end

  it "処理待ちが十分にあれば何もしない" do
    create_list(:crawl_request, described_class::LOW_WATER)
    create(:anime)

    expect { described_class.perform_now }.not_to change(CrawlRequest, :count)
  end
end
