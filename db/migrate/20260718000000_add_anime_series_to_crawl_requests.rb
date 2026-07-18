class AddAnimeSeriesToCrawlRequests < ActiveRecord::Migration[8.1]
  def change
    add_reference :crawl_requests, :anime_series, foreign_key: true
    change_column_null :crawl_requests, :anime_id, true

    # クロール対象は「アニメ単体」か「シリーズ」のどちらか一方のみ
    add_check_constraint :crawl_requests,
      "(anime_id IS NULL) <> (anime_series_id IS NULL)",
      name: "crawl_requests_exactly_one_target"
  end
end
