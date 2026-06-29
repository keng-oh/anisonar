module Spotify
  # Client Credentials Flow でアクセストークンを取得し、トラック検索を行う。
  # ユーザー認証は不要（公開カタログ検索のみ）。
  class Client
    class Error < StandardError; end

    TOKEN_URL = "https://accounts.spotify.com/api/token"
    API_URL   = "https://api.spotify.com/v1"
    TOKEN_CACHE_KEY = "spotify:access_token"

    def initialize(client_id: ENV["SPOTIFY_CLIENT_ID"], client_secret: ENV["SPOTIFY_CLIENT_SECRET"])
      @client_id     = client_id
      @client_secret = client_secret
      @conn = Faraday.new do |f|
        f.response :json
        f.request :retry, max: 2, interval: 1, backoff_factor: 2
        f.options.timeout = 10
      end
    end

    # query 例: 'track:"曲名" artist:"アーティスト名"'
    # @return [Array<Hash>] トラック情報の配列（最大 limit 件）
    def search_track(query, limit: 5)
      search(type: "track", query: query, limit: limit)
    end

    # @return [Array<Hash>] アーティスト情報の配列（最大 limit 件）
    def search_artist(query, limit: 5)
      search(type: "artist", query: query, limit: limit)
    end

    # 検索でうまく見つからない曲を、トラックIDを直接指定して取得する用途。
    # @return [Hash] トラック情報
    def get_track(id)
      raise Error, "SPOTIFY_CLIENT_ID/SECRET is not set" if @client_id.blank? || @client_secret.blank?

      res = @conn.get("#{API_URL}/tracks/#{id}") do |req|
        req.headers["Authorization"] = "Bearer #{access_token}"
      end

      raise Error, "HTTP #{res.status}: #{res.body.inspect}" unless res.success?
      res.body
    end

    private

      def search(type:, query:, limit:)
        raise Error, "SPOTIFY_CLIENT_ID/SECRET is not set" if @client_id.blank? || @client_secret.blank?

        res = @conn.get("#{API_URL}/search") do |req|
          req.headers["Authorization"] = "Bearer #{access_token}"
          req.params["q"]     = query
          req.params["type"]  = type
          req.params["limit"] = limit
        end

        raise Error, "HTTP #{res.status}: #{res.body.inspect}" unless res.success?
        res.body.dig("#{type}s", "items") || []
      end

      def access_token
        Rails.cache.fetch(TOKEN_CACHE_KEY, expires_in: 50.minutes) { fetch_token }
      end

      def fetch_token
        res = @conn.post(TOKEN_URL) do |req|
          req.headers["Authorization"] = "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
          req.headers["Content-Type"] = "application/x-www-form-urlencoded"
          req.body = URI.encode_www_form(grant_type: "client_credentials")
        end

        raise Error, "Token request failed: HTTP #{res.status}: #{res.body.inspect}" unless res.success?
        res.body["access_token"]
      end
  end
end
