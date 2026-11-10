module Notifications
  module Channels
    class Ntfy
      def initialize(url: ENV["NTFY_URL"], username: ENV["NTFY_USERNAME"], password: ENV["NTFY_PASSWORD"])
        @url = url.presence
        @username = username.presence
        @password = password
      end

      def notify(message, title: "Anisonar Error", priority: "high")
        return if @url.nil?

        headers = { "Title" => encode_header(title), "Priority" => priority }
        headers["Authorization"] = basic_auth_header if @username

        Faraday.post(@url, message, headers)
      rescue => e
        Rails.logger.error "[Notifications::Channels::Ntfy] notification failed: #{e.message}"
      end

      private

        # HTTP ヘッダは ASCII が前提。日本語のタイトルは ntfy が解釈する RFC 2047 の形にする
        def encode_header(value)
          value.ascii_only? ? value : "=?UTF-8?B?#{Base64.strict_encode64(value)}?="
        end

        def basic_auth_header
          "Basic #{Base64.strict_encode64("#{@username}:#{@password}")}"
        end
    end
  end
end
