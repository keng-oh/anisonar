module Admin
  module DataChecksHelper
    # 点検で見つかったレコードの編集画面（無いものは関連する一覧）へのパス。レコードが消えていれば nil
    def data_check_record_path(finding)
      record = finding.record
      case record
      when Song then edit_admin_song_path(record)
      when Artist then edit_admin_artist_path(record)
      when Anime then edit_admin_anime_path(record)
      when AnimeSeries then anime_series_path(record)
      when CrawlRequest then crawl_requests_admin_integrations_path(status: "failed")
      end
    end
  end
end
