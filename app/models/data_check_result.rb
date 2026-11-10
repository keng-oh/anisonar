# 1回の実行における、点検項目ごとの結果。項目が失敗したときは error_message が入る
class DataCheckResult < ApplicationRecord
  belongs_to :data_check_run
  has_many :findings, class_name: "DataCheckFinding", dependent: :destroy

  def failed?
    error_message.present?
  end
end
