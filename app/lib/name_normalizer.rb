# アーティスト名・楽曲タイトルの表記揺れを吸収した重複判定用キーを作る。
# 表示値そのものの正規化は NameFormatter が行い、こちらは比較（マッチング）専用。
# アーティストではこの結果を artists.normalized_name に保存して照合に使う。
module NameNormalizer
  # 空白の有無の表記揺れ（例: Spotify側「梶浦 由記」 vs クロール側「梶浦由記」）を
  # 完全一致判定で吸収するため、空白は圧縮ではなく完全に除去する。
  # NFKCにより ！？（） の全角・半角差もここで吸収される（表示値では保持される差）。
  # また「名前（役名）」の繰り返しにおける区切り文字の表記揺れ（・ と 、）も、
  # ）の直後に限定して 、 に統一する（NameFormatter と正規形を揃えるため。
  # カッコを伴わない箇所の ・/、 は意味を持つ場合があるため対象にしない）。
  # NFKC正規化で全角括弧は半角に変換されるため、ここでは半角 ) のみを見ればよい。
  def self.call(str)
    str.to_s.unicode_normalize(:nfkc).downcase.gsub(/\s+/, "").gsub(/\)・/, ")、")
  end

  # 「アクア（雨宮天）」と Spotify の「アクア (CV: 雨宮 天)」を同じとみなす比較キー
  # （call の結果から「CV:」も落とす）。クレジットの名義の照合に使う。
  def self.credit_key(str)
    call(str).gsub(/cv[.:：]?/, "")
  end

  # 作品名の比較キー。記号を全部落とす（「〈物語〉シリーズ」と「物語シリーズ」が同じになる）。
  def self.title_key(str)
    call(str).gsub(/[^\p{L}\p{N}]/, "")
  end
end
