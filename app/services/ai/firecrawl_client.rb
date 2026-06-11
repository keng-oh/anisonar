module Ai
  # Firecrawl セルフホスト版クライアント。
  # 指定 URL を Markdown に変換して返す。
  #
  # 環境変数:
  #   FIRECRAWL_URL     — Firecrawl サーバーのベース URL（例: http://192.168.1.10:3002）
  #   FIRECRAWL_API_KEY — 認証キー（セルフホストでは任意文字列でもOK）
  class FirecrawlClient
    class Error < StandardError; end

    DEFAULT_URL    = "http://localhost:3002"
    TIMEOUT_SEC    = 30
    MAX_CHARS      = 8_000 # Claude に渡す最大文字数（長すぎるページを切り詰める）

    def initialize(
      base_url: ENV.fetch("FIRECRAWL_URL", DEFAULT_URL),
      api_key:  ENV.fetch("FIRECRAWL_API_KEY", "")
    )
      @api_key = api_key
      @conn = Faraday.new(url: base_url) do |f|
        f.request  :json
        f.response :json
        f.request  :retry, max: 1, interval: 2
        f.options.timeout = TIMEOUT_SEC
      end
    end

    # URL を Markdown 文字列にして返す。
    # 失敗時は Error を raise する。
    #
    # @param url [String]
    # @return [String] Markdown テキスト（MAX_CHARS まで）
    def scrape(url)
      res = @conn.post("/v1/scrape") do |req|
        req.headers["Authorization"] = "Bearer #{@api_key}"
        req.body = { url: url, formats: [ "markdown" ] }
      end

      raise Error, "HTTP #{res.status}: #{res.body.inspect}" unless res.success?
      raise Error, "Firecrawl error: #{res.body['error']}" if res.body["error"].present?

      markdown = res.body.dig("data", "markdown").to_s
      markdown.slice(0, MAX_CHARS)
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
      raise Error, "Firecrawl 接続エラー: #{e.message}"
    end
  end
end
