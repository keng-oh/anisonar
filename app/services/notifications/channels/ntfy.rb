module Notifications
  module Channels
    class Ntfy
      def initialize(url: ENV["NTFY_URL"], username: ENV["NTFY_USERNAME"], password: ENV["NTFY_PASSWORD"])
        @url = url.presence
        @username = username.presence
        @password = password
      end

      def notify(message)
        return if @url.nil?

        headers = { "Title" => "Anisonar Error", "Priority" => "high" }
        headers["Authorization"] = basic_auth_header if @username

        Faraday.post(@url, message, headers)
      rescue => e
        Rails.logger.error "[Notifications::Channels::Ntfy] notification failed: #{e.message}"
      end

      private

        def basic_auth_header
          "Basic #{Base64.strict_encode64("#{@username}:#{@password}")}"
        end
    end
  end
end
