module Admin
  class DataChecksController < BaseController
    def index
      @running = DataCheckRun.in_progress.exists?
      @run = DataCheckRun.finished.order(started_at: :desc).first
      @results = @run ? @run.results.index_by(&:check_key) : {}
      @deltas = @run ? DataChecks::Delta.for_run(@run) : {}
    end

    def show
      @check = DataChecks::Registry.find(params[:id])
      return head :not_found unless @check

      @run = DataCheckRun.finished.order(started_at: :desc).first
      @result = @run&.results&.find_by(check_key: @check::KEY)
      findings = @result ? @result.findings.includes(:record).order(:id) : DataCheckFinding.none
      @pagy, @findings = pagy(:offset, findings, limit: 50)
      @reasons = crawl_failure_reasons if @result && @check == DataChecks::CrawlFailures
    end

    def create
      if DataCheckRun.in_progress.exists?
        redirect_to admin_data_checks_path, notice: "点検は実行中です"
      else
        DataCheckJob.perform_later("manual")
        redirect_to admin_data_checks_path, notice: "点検を開始しました。終わるまで数分かかることがあります"
      end
    end

    private

      # 失敗したクロール依頼を、理由の見出しごとに数える（多い順）
      def crawl_failure_reasons
        @result.findings.pluck(:detail)
               .map { |detail| DataChecks::CrawlFailures.reason_of(detail) }
               .tally.sort_by { |reason, count| [ -count, reason ] }
      end
  end
end
