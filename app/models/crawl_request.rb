class CrawlRequest < ApplicationRecord
  belongs_to :anime, optional: true
  belongs_to :anime_series, optional: true

  enum :status, { pending: "pending", crawling: "crawling", crawled: "crawled", extracting: "extracting", done: "done", failed: "failed" }

  validate :exactly_one_target

  # クロール対象のアニメ一覧。シリーズ依頼なら所属アニメ全て、単体依頼ならそのアニメのみ。
  # includes(anime_series: :animes) を活かすため DB ではなくメモリ上でソートする
  def target_animes
    return [ anime ] unless anime_series

    anime_series.animes.sort_by { |a| [ a.series_order || Float::INFINITY, a.season.to_s, a.id ] }
  end

  def target_urls
    target_animes.flat_map { |a| [ a.wikipedia_url, a.official_site_url ] }.compact_blank.uniq
  end

  def target_label
    anime_series ? "#{anime_series.name}（シリーズ）" : anime.title
  end

  private

    def exactly_one_target
      return if anime.present? ^ anime_series.present?

      errors.add(:base, "アニメかシリーズのどちらか一方を指定してください")
    end
end
