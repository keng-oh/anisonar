# 実質同じページを指すURLを1件に寄せる。
#
# クロール対象URLは、アニメごとに登録された wikipedia_url / official_site_url を
# 集めたものなので、スキーム（http/https）や末尾スラッシュの違いで同じページが
# 複数残りやすい。重複した分だけ探索サブワークフローと scrape が余計に走る。
#
# 同一とみなす条件はホスト（大文字小文字を無視）＋パス（末尾スラッシュを無視）＋クエリ。
# クエリはページが変わる場合があるため区別する。www の有無は別ホストとして扱う
# （実際に別サイトのことがあるため、機械的に寄せると取りこぼす）。
#
# 出力するURLは入力に存在した文字列そのままで、書き換えはしない。
# http しか無いサイトを https に上げると到達できなくなるため、
# https は「候補にあれば優先する」だけに留める。
module UrlDeduplicator
  def self.call(urls)
    urls.compact_blank.each_with_object({}) { |url, chosen|
      key     = dedup_key(url)
      current = chosen[key]
      chosen[key] = url if current.nil? || prefer_https?(url, current)
    }.values
  end

  # URI.parse は非ASCIIを含むURLで例外になる（日本語のWikipedia URLが該当）ため使わない。
  # ここで欲しいのは比較用のキーだけなので、自前で分解する。
  URL_PATTERN = %r{\A[a-z][a-z0-9+.\-]*://(?<host>[^/?#]+)(?<path>[^?#]*)(?:\?(?<query>[^#]*))?}i

  # 形式が想定外のURLは重複判定の対象外とし、値そのものをキーにして素通しする
  # （クロール対象から勝手に落とすと、単に取りこぼしになるため）。
  def self.dedup_key(url)
    m = URL_PATTERN.match(url.to_s.strip)
    return [ :unparsable, url ] if m.nil?

    "#{m[:host].downcase}#{decoded_path(m[:path])}?#{m[:query]}"
  end
  private_class_method :dedup_key

  # 日本語を含むURLは、そのまま登録されたものとパーセントエンコードされたものが
  # 混在する（Wikipediaで実際に発生）。デコードしてから比較しないと同一と判定できない。
  # decode_uri_component は + を空白に変換しないため、パスのデコードに適している。
  def self.decoded_path(path)
    URI.decode_uri_component(path.chomp("/"))
  rescue ArgumentError
    path.chomp("/")
  end
  private_class_method :decoded_path

  def self.prefer_https?(candidate, current)
    candidate.start_with?("https://") && !current.start_with?("https://")
  end
  private_class_method :prefer_https?
end
