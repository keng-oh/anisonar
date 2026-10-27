require 'rails_helper'

RSpec.describe NameFormatter do
  describe ".call" do
    it "「キャラクター名 (声優名)」の半角かっこを全角にそろえる" do
      expect(described_class.call("ユイ (LiSA)")).to eq "ユイ（LiSA）"
    end

    it "連名でもそれぞれのかっこを全角にそろえる" do
      expect(described_class.call("千反田える(佐藤聡美)、伊原摩耶花 (茅野愛衣)"))
        .to eq "千反田える（佐藤聡美）、伊原摩耶花（茅野愛衣）"
    end

    it "名前の先頭にあるかっこは名前の一部として残す" do
      expect(described_class.call("(K)NoW_NAME")).to eq "(K)NoW_NAME"
    end

    it "全角のかっこはそのまま残す" do
      expect(described_class.call("アクア（雨宮天）")).to eq "アクア（雨宮天）"
    end

    it "！？ の幅は書かれた通りに残す" do
      expect(described_class.call("すーぱーびっぐらぶ！")).to eq "すーぱーびっぐらぶ！"
      expect(described_class.call("go!go!vanillas")).to eq "go!go!vanillas"
    end

    it "かっこの直後の ・ を 、 にそろえる" do
      expect(described_class.call("アクア(雨宮天)・めぐみん(高橋李依)")).to eq "アクア（雨宮天）、めぐみん（高橋李依）"
    end
  end
end
