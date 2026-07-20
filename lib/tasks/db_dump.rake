namespace :db do
  desc "DBのダンプを tmp/dumps/ に取得する（DbDumpJobの手動実行）"
  task dump: :environment do
    DbDumpJob.perform_now
  end
end
