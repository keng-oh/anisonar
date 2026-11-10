require "rails_helper"

RSpec.describe NameNormalizer do
  describe ".credit_key" do
    it "「CV:」・空白・全角半角の違いを無視する" do
      expect(described_class.credit_key("めぐみん (CV: 高橋李依)")).to eq(described_class.credit_key("めぐみん（高橋李依）"))
    end
  end

  describe ".title_key" do
    it "記号の違いを無視する" do
      expect(described_class.title_key("〈物語〉シリーズ")).to eq(described_class.title_key("物語シリーズ"))
    end
  end
end
