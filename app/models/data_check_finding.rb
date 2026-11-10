# 点検で見つかった怪しいレコード。レコードが後で消えても一覧が壊れないよう、表示名を記録時点で持つ
class DataCheckFinding < ApplicationRecord
  belongs_to :data_check_result
  belongs_to :record, polymorphic: true, optional: true
end
