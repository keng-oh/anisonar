require 'rails_helper'

RSpec.describe Anime, type: :model do
  describe ".seasons_until" do
    it "今のシーズンまでの直近の年のシーズンを返す（1〜3月が winter）" do
      expect(described_class.seasons_until(Date.new(2026, 2, 1), years: 1)).to eq [ "2026-winter" ]
      expect(described_class.seasons_until(Date.new(2026, 10, 1), years: 1)).to eq %w[2026-winter 2026-spring 2026-summer 2026-autumn]
    end
  end

  describe "クロール依頼のスコープ" do
    let(:series) { create(:anime_series) }
    let!(:in_requested_series) { create(:anime, anime_series: series) }
    let!(:requested) { create(:anime) }
    let!(:fresh) { create(:anime) }

    before do
      create(:crawl_request, :for_series, anime_series: series, status: :failed)
      create(:crawl_request, anime: requested, status: :pending)
    end

    it "without_crawl_request は、自身にもシリーズにも依頼が無いアニメ" do
      expect(described_class.without_crawl_request).to contain_exactly(fresh)
    end

    it "with_crawl_status は、自身かシリーズへの依頼の状態で絞り込む" do
      expect(described_class.with_crawl_status("failed")).to contain_exactly(in_requested_series)
      expect(described_class.with_crawl_status(%w[pending crawling])).to contain_exactly(requested)
    end
  end
end
