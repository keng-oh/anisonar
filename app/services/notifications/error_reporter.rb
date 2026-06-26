module Notifications
  # Rails.error.subscribe の購読先。Web側の未処理例外・Sidekiqジョブの最終失敗を
  # 一元的に受け取り、設定済みの通知チャネル(ntfy/Discordなど)へ送る
  class ErrorReporter
    CHANNELS = [ Channels::Ntfy.new, Channels::Discord.new ].freeze

    def self.report(error, handled: true, severity: :error, context: {}, source: nil)
      new(error, handled:, severity:, context:, source:).report
    end

    def initialize(error, handled:, severity:, context:, source:)
      @error = error
      @handled = handled
      @severity = severity
      @context = context
      @source = source
    end

    def report
      # rescue_fromで捕捉済み・想定内のエラーは通知しない
      return if @handled

      CHANNELS.each { |channel| channel.notify(message) }
    end

    private

      def message
        location = @source.presence || @context[:job_class].presence || "unknown"
        "[Anisonar] (#{location}) #{@error.class}: #{@error.message}"
      end
  end
end
