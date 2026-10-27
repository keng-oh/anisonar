# 連名のクレジット（「鈴木このみ feat. Ashnikko」「アクア（雨宮天）、めぐみん（高橋李依）」）を
# メンバーの名前の候補に分ける。結果は管理画面で人が確認してから確定する前提なので、
# ユニット名にも含まれる「&」「,」（MYTH & ROID など）でも分ける。
# かっこの中（「TK（凛として時雨）」「キャラ（声優A、声優B）」）では分けない。
module JointNameSplitter
  DELIMITER = /\s+(?:feat\.?|ft\.|featuring|starring|with|x)\s+|\s+\/\s+|\s*[、×&,，]\s*/i
  # 一覧の「連名（未分解）」の絞り込みに使う PostgreSQL の正規表現（DELIMITER と同じ区切り。かっこの中かは見ない）
  SQL_PATTERN = '\s(feat\.?|ft\.|featuring|starring|with|x)\s|\s/\s|[、×&,，]'
  OPEN = "(（".freeze
  CLOSE = ")）".freeze

  Span = Data.define(:text, :from, :to)

  # @return [Array<String>] 分けられなければ空配列
  def self.call(name)
    spans(name).map(&:text)
  end

  # 断片と、元の名前の中での位置（to は含まない）。隣り合う断片をつないだ元の表記を取り出すのに使う
  # @return [Array<Span>] 分けられなければ空配列
  def self.spans(name)
    name = name.to_s
    scanner = StringScanner.new(name)
    spans = []
    from = 0
    depth = 0
    until scanner.eos?
      pos = scanner.charpos
      if depth.zero? && scanner.scan(DELIMITER)
        spans << span(name, from, pos)
        from = scanner.charpos
        next
      end
      char = scanner.getch
      depth += 1 if OPEN.include?(char)
      depth -= 1 if CLOSE.include?(char) && depth.positive?
    end
    spans << span(name, from, name.length)
    spans = spans.compact
    spans.size > 1 ? spans : []
  end

  def self.span(name, from, to)
    text = name[from...to]
    lead = text.length - text.lstrip.length
    text = text.strip
    return nil if text.empty?

    Span.new(text: text, from: from + lead, to: from + lead + text.length)
  end
  private_class_method :span
end
