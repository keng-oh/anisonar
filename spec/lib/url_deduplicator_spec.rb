require 'rails_helper'

RSpec.describe UrlDeduplicator do
  describe ".call" do
    # Issue #30 に記録されたRe:ゼロの依頼（id=15）の実例
    it "スキームと末尾スラッシュの違いを吸収して1件に寄せる" do
      urls = [
        "http://re-zero-anime.jp/",
        "http://re-zero-anime.jp",
        "https://re-zero-anime.jp/",
        "http://re-zero-anime.jp/tv/",
        "https://re-zero-anime.jp/tv/"
      ]

      expect(described_class.call(urls)).to eq([
        "https://re-zero-anime.jp/",
        "https://re-zero-anime.jp/tv/"
      ])
    end

    # 日本語URLは、そのまま登録されたものとエンコード済みのものが混在する（Wikipediaで実際に発生）
    it "パーセントエンコードの有無を吸収する" do
      urls = [
        "https://ja.wikipedia.org/wiki/Re:ゼロから始める異世界生活",
        "https://ja.wikipedia.org/wiki/Re:%E3%82%BC%E3%83%AD%E3%81%8B%E3%82%89%E5%A7%8B%E3%82%81%E3%82%8B%E7%95%B0%E4%B8%96%E7%95%8C%E7%94%9F%E6%B4%BB"
      ]

      expect(described_class.call(urls)).to eq([ "https://ja.wikipedia.org/wiki/Re:ゼロから始める異世界生活" ])
    end

    it "エンコードしても別ページになるURLは区別する" do
      urls = [
        "https://ja.wikipedia.org/wiki/Re:ゼロから始める異世界生活",
        "https://ja.wikipedia.org/wiki/Re:%E3%82%BC%E3%83%AD%E3%81%8B%E3%82%89%E5%A7%8B%E3%82%81%E3%82%8B%E7%95%B0%E4%B8%96%E7%95%8C%E7%94%9F%E6%B4%BB_(%E3%82%A2%E3%83%8B%E3%83%A1)"
      ]

      expect(described_class.call(urls).size).to eq(2)
    end

    it "不正なエスケープを含むURLでも落ちない" do
      urls = [ "https://example.com/%%%", "https://example.com/a" ]

      expect(described_class.call(urls).size).to eq(2)
    end

    it "httpしか無い場合はhttpのまま残す" do
      expect(described_class.call([ "http://example.com/" ])).to eq([ "http://example.com/" ])
    end

    it "ホストの大文字小文字を無視する" do
      expect(described_class.call([ "https://Example.com/", "https://example.com" ])).to eq([ "https://Example.com/" ])
    end

    it "パスが違うURLは別物として残す" do
      urls = [ "https://example.com/a", "https://example.com/b" ]

      expect(described_class.call(urls)).to eq(urls)
    end

    it "クエリが違うURLは別物として残す" do
      urls = [ "https://example.com/?p=1", "https://example.com/?p=2" ]

      expect(described_class.call(urls)).to eq(urls)
    end

    # wwwの有無は実際に別サイトのことがあるため寄せない
    it "wwwの有無は別ホストとして扱う" do
      urls = [ "https://example.com/", "https://www.example.com/" ]

      expect(described_class.call(urls)).to eq(urls)
    end

    it "空・nilを取り除く" do
      expect(described_class.call([ nil, "", "  ", "https://example.com" ])).to eq([ "https://example.com" ])
    end

    # クロール対象から勝手に落とさない
    it "パースできない値はそのまま残す" do
      expect(described_class.call([ "not a url", "https://example.com" ])).to eq([ "not a url", "https://example.com" ])
    end

    it "入力順を保つ" do
      urls = [ "https://b.example.com/", "https://a.example.com/" ]

      expect(described_class.call(urls)).to eq(urls)
    end
  end
end
