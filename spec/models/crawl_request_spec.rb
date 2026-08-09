require 'rails_helper'

RSpec.describe CrawlRequest, type: :model do
  describe "#target_urls" do
    it "アニメのwikipedia_urlとofficial_site_urlを返す" do
      anime = create(:anime, wikipedia_url: "https://ja.wikipedia.org/wiki/作品", official_site_url: "https://example.com/")
      request = create(:crawl_request, anime: anime)

      expect(request.target_urls).to contain_exactly("https://ja.wikipedia.org/wiki/作品", "https://example.com/")
    end

    it "未設定のURLを取り除く" do
      anime = create(:anime, wikipedia_url: nil, official_site_url: "https://example.com/")
      request = create(:crawl_request, anime: anime)

      expect(request.target_urls).to eq([ "https://example.com/" ])
    end

    # シリーズ依頼では所属アニメ全ての公式サイトが集まるため、
    # スキーム・末尾スラッシュ違いの重複が特に発生しやすい
    it "シリーズ内でスキーム・末尾スラッシュ違いの重複を寄せる" do
      series = create(:anime_series)
      create(:anime, anime_series: series, official_site_url: "http://re-zero-anime.jp/", wikipedia_url: nil)
      create(:anime, anime_series: series, official_site_url: "https://re-zero-anime.jp", wikipedia_url: nil)
      create(:anime, anime_series: series, official_site_url: "http://re-zero-anime.jp/tv/", wikipedia_url: nil)
      request = create(:crawl_request, :for_series, anime_series: series)

      expect(request.target_urls).to contain_exactly("https://re-zero-anime.jp", "http://re-zero-anime.jp/tv/")
    end
  end
end
