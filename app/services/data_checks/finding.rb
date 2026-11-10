module DataChecks
  # 点検項目が返す1件。record は管理画面で編集へ移るため、label は記録時点の表示名
  Finding = Data.define(:record, :label, :detail)
end
