module DataChecks
  class CrawlFailures
    KEY = "crawl_failures"
    LABEL = "クロールの失敗"
    DESCRIPTION = "失敗したままのクロール依頼がある"

    DETAIL_LENGTH = 300
    REASON_LENGTH = 40

    def self.call = new.call

    # エラーメッセージから、件数を数えるための理由の見出しを作る
    # （"; " で区切った先頭、「曲名」: を除き、数字を N に置き換えて 40 字で切る）
    def self.reason_of(message)
      reason = message.to_s.split("; ").first.to_s.sub(/\A「[^」]*」[:：]\s*/, "").strip
      return "（理由なし）" if reason.empty?

      reason.gsub(/\d+/, "N").truncate(REASON_LENGTH)
    end

    def call
      CrawlRequest.failed.includes(:anime, :anime_series).order(:id).map do |request|
        Finding.new(record: request, label: request.target_label, detail: request.error_message.to_s.first(DETAIL_LENGTH))
      end
    end
  end
end
