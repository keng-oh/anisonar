module Annict
  class Client
    ENDPOINT = "https://api.annict.com/graphql"

    class Error < StandardError; end

    def initialize(token: ENV["ANNICT_API_TOKEN"])
      @token = token
      @conn = Faraday.new(url: ENDPOINT) do |f|
        f.request :json
        f.response :json
        f.request :retry, max: 3, interval: 1, backoff_factor: 2
      end
    end

    def query(gql, variables: {})
      res = @conn.post do |req|
        req.headers["Authorization"] = "Bearer #{@token}"
        req.body = { query: gql, variables: }
      end

      raise Error, "HTTP #{res.status}" unless res.success?

      body = res.body
      raise Error, body["errors"].map { |e| e["message"] }.join(", ") if body["errors"].present?
      raise Error, "GraphQL response missing 'data' field" if body["data"].nil?

      body["data"]
    end
  end
end
