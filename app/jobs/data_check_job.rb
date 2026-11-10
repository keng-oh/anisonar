# 怪しいデータを洗い出して記録する（週1回の定期実行と、管理画面からの手動実行）
class DataCheckJob < ApplicationJob
  queue_as :default

  def perform(trigger = "scheduled")
    if DataCheckRun.in_progress.exists?
      Rails.logger.info "[DataCheckJob] skipped: a data check is already running"
      return
    end

    DataChecks::Runner.call(trigger:)
  end
end
