# アーティスト名を保存する前に整える、表示値そのものの正規化。
# 比較専用の NameNormalizer と違い、破壊的な変換（空白除去・小文字化・幅の強制統一）は行わない。
#
# NFKC正規化で全角英数・半角カナなどの表記揺れを吸収するが、！？（） だけは元の幅を保つ。
# NFKCはこれらを半角に寄せてしまい「すーぱーびっぐらぶ！」が壊れる一方、全角に寄せると
# 「go!go!vanillas」が壊れるため、どちらにも倒さず書かれた通りに残す。
# 幅の揺れを無視した同一判定は NameNormalizer（比較キー）側の責務。
module NameFormatter
  KEEP_WIDTH = /[！？（）]/

  def self.call(str)
    return str if str.nil?

    # 幅を保ちたい文字を避け、それ以外の連続部分にのみNFKCを適用する
    formatted = str.to_s
                   .gsub(/[^！？（）]+/) { Regexp.last_match(0).unicode_normalize(:nfkc) }
                   .gsub(/\s+/, " ")
                   .strip

    # 「名前（役名）」を並べる際の区切り文字は ・ ではなく 、 に統一する。
    # ・ は「アイナ・ジ・エンド」のように名前自体に含まれるため区切りとしては曖昧だが、
    # ）の直後の ・ は区切りとみなせるので、その位置に限定して変換する。
    formatted.gsub(/([)）])・/, '\1、')
  end
end
