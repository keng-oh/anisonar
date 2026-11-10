module DataChecks
  # 点検を全項目実行して結果を記録し、要約を通知する。
  # 1項目が例外で失敗しても、ほかの項目は続ける
  class Runner
    INSERT_BATCH_SIZE = 1000

    def self.call(trigger:, checks: Registry::CHECKS, notifier: SummaryNotifier)
      new(trigger:, checks:, notifier:).call
    end

    def initialize(trigger:, checks:, notifier:)
      @trigger = trigger
      @checks = checks
      @notifier = notifier
    end

    def call
      run = DataCheckRun.create!(trigger: @trigger, status: :running, started_at: Time.current)
      begin
        results = @checks.map { |check| execute(run, check) }
        all_failed = results.any? && results.all?(&:failed?)
        run.update!(status: all_failed ? :failed : :succeeded, finished_at: Time.current)
      rescue => e
        run.update!(status: :failed, finished_at: Time.current, error_message: e.message)
        raise
      end

      notify(run)
      run
    end

    private

      def execute(run, check)
        findings = check.call
        result = run.results.create!(check_key: check::KEY, findings_count: findings.size)
        save_findings(result, findings)
        result
      rescue => e
        Rails.error.report(e, handled: true, context: { check_key: check::KEY })
        run.results.find_or_initialize_by(check_key: check::KEY).tap do |result|
          result.update!(findings_count: 0, error_message: "#{e.class}: #{e.message}".truncate(1000))
          DataCheckFinding.where(data_check_result_id: result.id).delete_all
        end
      end

      def save_findings(result, findings)
        findings.each_slice(INSERT_BATCH_SIZE) do |slice|
          DataCheckFinding.insert_all(slice.map { |finding|
            {
              data_check_result_id: result.id,
              record_type: finding.record&.class&.polymorphic_name,
              record_id: finding.record&.id,
              label: finding.label,
              detail: finding.detail
            }
          })
        end
      end

      # 通知の失敗で、記録した点検結果を失敗扱いにしない
      def notify(run)
        @notifier.call(run)
      rescue => e
        Rails.error.report(e, handled: true, context: { source: "data_checks" })
      end
  end
end
