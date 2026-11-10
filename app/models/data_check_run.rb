# 点検の1回分の実行記録。実行ごとの結果は DataCheckResult に持つ
class DataCheckRun < ApplicationRecord
  # 落ちて running のまま残った実行を、実行中とみなさなくなるまでの時間
  STALE_AFTER = 1.hour

  has_many :results, class_name: "DataCheckResult", dependent: :destroy

  enum :trigger, { scheduled: "scheduled", manual: "manual" }
  enum :status, { running: "running", succeeded: "succeeded", failed: "failed" }

  scope :finished, -> { where.not(status: :running) }
  # 今まさに動いているとみなす実行（古い running は落ちたものとして無視する）
  scope :in_progress, -> { running.where(started_at: STALE_AFTER.ago..) }
end
