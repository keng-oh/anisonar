module Spotify
  # Client Credentials Flow でアクセストークンを取得し、トラック検索を行う。
  # ユーザー認証は不要（公開カタログ検索のみ）。
  class Client
    class Error < StandardError; end

    TOKEN_URL = "https://accounts.spotify.com/api/token"
    API_URL   = "https://api.spotify.com/v1"
    TOKEN_CACHE_KEY = "spotify:access_token"
    RATE_LIMIT_CACHE_KEY = "spotify:rate_limited_until"
    # 429 の Retry-After がこれより長ければ待たずに諦める。Spotify は制限が重いと数時間を返すことがあり、
    # そのまま待つと Sidekiq のスレッドが何時間も止まり、楽曲の取り込みまで進まなくなる
    MAX_RETRY_WAIT = 30
    DEFAULT_RATE_LIMIT_WAIT = 60

    # レート制限が解けるまでの時刻（制限中でなければ nil）
    def self.rate_limited_until
      until_time = Rails.cache.read(RATE_LIMIT_CACHE_KEY)
      until_time if until_time && until_time > Time.current
    end

    def initialize(client_id: ENV["SPOTIFY_CLIENT_ID"], client_secret: ENV["SPOTIFY_CLIENT_SECRET"])
      @client_id     = client_id
      @client_secret = client_secret
      @conn = Faraday.new do |f|
        f.response :json
        # 429 は Retry-After を守って待つ（faraday-retry は retry_statuses の応答で Retry-After を優先する）。
        # Retry-After が max_interval を超えるときは待たずに 429 を返す
        f.request :retry, max: 2, interval: 1, backoff_factor: 2, retry_statuses: [ 429 ], max_interval: MAX_RETRY_WAIT
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
      get("#{API_URL}/tracks/#{id}")
    end

    # 検索でうまく見つからないアーティストを、アーティストIDを直接指定して取得する用途。
    # @return [Hash] アーティスト情報
    def get_artist(id)
      get("#{API_URL}/artists/#{id}")
    end

    private

      def get(url)
        raise Error, "SPOTIFY_CLIENT_ID/SECRET is not set" if @client_id.blank? || @client_secret.blank?

        ensure_not_rate_limited!
        res = @conn.get(url) do |req|
          req.headers["Authorization"] = "Bearer #{access_token}"
        end

        handle_error!(res)
        res.body
      end

      def search(type:, query:, limit:)
        raise Error, "SPOTIFY_CLIENT_ID/SECRET is not set" if @client_id.blank? || @client_secret.blank?

        ensure_not_rate_limited!
        res = @conn.get("#{API_URL}/search") do |req|
          req.headers["Authorization"] = "Bearer #{access_token}"
          req.params["q"]      = query
          req.params["type"]   = type
          req.params["limit"]  = limit
          req.params["market"] = "JP"
        end

        handle_error!(res)
        res.body.dig("#{type}s", "items") || []
      end

      # 制限中は API を呼ばずにすぐ失敗させる（呼ぶほど制限が延びるため）。呼び出し側は Error を記録して次へ進む
      def ensure_not_rate_limited!
        until_time = self.class.rate_limited_until
        raise Error, "Spotify のレート制限中（#{until_time.iso8601} まで）" if until_time
      end

      def handle_error!(res)
        return if res.success?

        if res.status == 429
          wait = res.headers["retry-after"].to_i
          wait = DEFAULT_RATE_LIMIT_WAIT unless wait.positive?
          Rails.cache.write(RATE_LIMIT_CACHE_KEY, wait.seconds.from_now, expires_in: wait.seconds)
          raise Error, "HTTP 429: Spotify のレート制限（Retry-After: #{wait}秒）"
        end
        raise Error, "HTTP #{res.status}: #{res.body.inspect}"
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
