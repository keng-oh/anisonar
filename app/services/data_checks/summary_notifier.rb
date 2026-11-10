module DataChecks
  # 点検の要約を ntfy / Discord に送る。件数が 0 でも毎回送る（動いたことが分かるように）
  class SummaryNotifier
    TITLE = "Anisonar データの点検"

    def self.call(run, ntfy: Notifications::Channels::Ntfy.new, discord: Notifications::Channels::Discord.new)
      new(run).deliver(ntfy:, discord:)
    end

    def initialize(run)
      @run = run
    end

    def deliver(ntfy:, discord:)
      body = message
      ntfy.notify(body, title: TITLE, priority: "default")
      discord.notify(body, title: TITLE)
    end

    def message
      deltas = Delta.for_run(@run)
      results = @run.results.index_by(&:check_key)

      lines = [ "データの点検（#{@run.started_at.strftime('%Y-%m-%d')}）" ]
      Registry::CHECKS.each do |check|
        result = results[check::KEY]
        next if result.nil?

        lines << (result.failed? ? "#{check::LABEL}: 失敗" : "#{check::LABEL}: #{result.findings_count}件（#{Delta.format(deltas[check::KEY])}）")
      end
      lines << url
      lines.join("\n")
    end

    private

      def url
        Rails.application.routes.url_helpers.admin_data_checks_url(**Rails.application.config.action_mailer.default_url_options)
      end
  end
end
