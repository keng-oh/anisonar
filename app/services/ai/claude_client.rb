module Ai
  class ClaudeClient
    ENDPOINT = "https://api.anthropic.com/v1/messages"
    API_VERSION = "2023-06-01"
    DEFAULT_MODEL = "claude-haiku-4-5"

    class Error < StandardError; end

    def initialize(api_key: ENV["ANTHROPIC_API_KEY"], model: DEFAULT_MODEL)
      @api_key = api_key
      @model   = model
      @conn = Faraday.new(url: ENDPOINT) do |f|
        f.request :json
        f.response :json
        f.request :retry, max: 2, interval: 2, backoff_factor: 2
        f.options.timeout = 120
      end
    end

    # messages: [{ role:, content: }, ...]
    # tools: optional Array of tool definitions
    # max_tokens: defaults to 8000 (enough for tool output)
    def create_message(messages:, tools: nil, max_tokens: 8000, system: nil)
      raise Error, "ANTHROPIC_API_KEY is not set" if @api_key.blank?

      body = { model: @model, max_tokens: max_tokens, messages: messages }
      body[:tools]  = tools  if tools.present?
      body[:system] = system if system.present?

      res = @conn.post do |req|
        req.headers["x-api-key"]         = @api_key
        req.headers["anthropic-version"] = API_VERSION
        req.body = body
      end

      raise Error, "HTTP #{res.status}: #{res.body.inspect}" unless res.success?
      res.body
    end
  end
end
