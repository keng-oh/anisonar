module DataChecks
  # 前回の点検からの件数の増減
  module Delta
    # 今回の実行の直前に終わった成功した実行と比べる。前回が無い・その項目が無い・
    # どちらかの項目が失敗しているときは nil
    # @return [Hash{String => Integer, nil}] check_key => 増減
    def self.for_run(run)
      previous = DataCheckRun.succeeded.where(finished_at: ...run.started_at).order(finished_at: :desc).first
      previous_results = previous ? previous.results.index_by(&:check_key) : {}

      run.results.to_h do |result|
        before = previous_results[result.check_key]
        delta = result.findings_count - before.findings_count if before && !before.failed? && !result.failed?
        [ result.check_key, delta ]
      end
    end

    def self.format(delta)
      return "—" if delta.nil?

      delta.zero? ? "±0" : Kernel.format("%+d", delta)
    end
  end
end
