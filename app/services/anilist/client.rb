module Anilist
  # AniList GraphQL API クライアント。認証不要の公開API。
  # レート制限: 30 req/min 程度を想定し、呼び出し側でインターバルを設けること。
  class Client
    class Error < StandardError; end

    ENDPOINT = "https://graphql.anilist.co"

    QUERY = <<~GQL
      query ($search: String) {
        Media(search: $search, type: ANIME) {
          title { romaji english native }
          coverImage { extraLarge large }
        }
      }
    GQL

    def initialize
      @conn = Faraday.new(url: ENDPOINT) do |f|
        f.request :json
        f.response :json
        f.request :retry, max: 2, interval: 2, backoff_factor: 2
        f.options.timeout = 15
      end
    end

    # @param title [String] 検索タイトル（日本語可）
    # @return [Hash, nil] Media オブジェクト（見つからない場合 nil）
    def search_media(title)
      res = @conn.post do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = { query: QUERY, variables: { search: title } }
      end

      raise Error, "HTTP #{res.status}: #{res.body.inspect}" unless res.success?
      raise Error, res.body["errors"].map { |e| e["message"] }.join(", ") if res.body["errors"].present?

      res.body.dig("data", "Media")
    end
  end
end
