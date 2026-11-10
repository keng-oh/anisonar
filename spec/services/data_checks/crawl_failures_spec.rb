require 'rails_helper'

RSpec.describe DataChecks::CrawlFailures do
  describe ".call" do
    it "failed の依頼だけを拾い、エラーメッセージを先頭 300 字まで detail に入れる" do
      failed = create(:crawl_request, status: :failed, error_message: "あ" * 400)
      create(:crawl_request, status: :pending)
      create(:crawl_request, status: :done)

      findings = described_class.call
      expect(findings.map(&:record)).to eq([ failed ])
      expect(findings.first.detail.length).to eq(300)
      expect(findings.first.label).to eq(failed.target_label)
    end
  end

  describe ".reason_of" do
    it "「曲名」: を除き、数字を N に置き換える" do
      expect(described_class.reason_of("「青春コンプレックス」: 依頼対象外の anime_id=12")).to eq("依頼対象外の anime_id=N")
    end

    it "複数の理由は先頭だけを使う" do
      expect(described_class.reason_of("「A」: 理由1; 「B」: 理由2")).to eq("理由N")
    end

    it "40 字で切る" do
      expect(described_class.reason_of("予期しないエラー: " + "x" * 100).length).to eq(40)
    end

    it "空なら（理由なし）" do
      expect(described_class.reason_of(nil)).to eq("（理由なし）")
    end
  end
end
