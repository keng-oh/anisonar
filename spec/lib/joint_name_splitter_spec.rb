require 'rails_helper'

RSpec.describe JointNameSplitter do
  describe ".call" do
    it "feat. で分ける" do
      expect(described_class.call("鈴木このみ feat. Ashnikko")).to eq [ "鈴木このみ", "Ashnikko" ]
    end

    it "「、」で分け、かっこの中の声優名は名前に残す" do
      expect(described_class.call("アクア（雨宮天）、めぐみん（高橋李依）、ダクネス（茅野愛衣）"))
        .to eq [ "アクア（雨宮天）", "めぐみん（高橋李依）", "ダクネス（茅野愛衣）" ]
    end

    it "×・starring・& でも分ける（& はユニット名にもあるので、確定は人が行う）" do
      expect(described_class.call("春奈るな×河野マリナ")).to eq [ "春奈るな", "河野マリナ" ]
      expect(described_class.call("神崎エルザ starring ReoNa")).to eq [ "神崎エルザ", "ReoNa" ]
      expect(described_class.call("MYTH & ROID")).to eq [ "MYTH", "ROID" ]
    end

    it "かっこの中の区切りでは分けない" do
      expect(described_class.call("キャラ（声優A、声優B）")).to eq []
      expect(described_class.call("MYTH & ROID feat. TK（凛として時雨）")).to eq [ "MYTH", "ROID", "TK（凛として時雨）" ]
    end

    it "区切りが無ければ空配列" do
      expect(described_class.call("fripSide")).to eq []
      expect(described_class.call("Wolpis Carter")).to eq []
    end
  end

  describe ".spans" do
    it "元の名前の中での位置を返す（マルチバイト文字を含む）" do
      name = "アクア（雨宮天）、めぐみん（高橋李依）"
      spans = described_class.spans(name)

      expect(spans.map { |s| name[s.from...s.to] }).to eq [ "アクア（雨宮天）", "めぐみん（高橋李依）" ]
    end
  end
end
