module Notifications
  module Channels
    class Discord
      def initialize(webhook_url: ENV["DISCORD_WEBHOOK_URL"])
        @webhook_url = webhook_url.presence
      end

      def notify(message)
        return if @webhook_url.nil?

        Faraday.post(@webhook_url) do |req|
          req.headers["Content-Type"] = "application/json"
          req.body = { content: message }.to_json
        end
      rescue => e
        Rails.logger.error "[Notifications::Channels::Discord] notification failed: #{e.message}"
      end
    end
  end
end
