require "open3"

class DbDumpJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  DUMP_DIR = Rails.root.join("tmp/dumps")
  KEEP_GENERATIONS = 3

  # DBのダンプを tmp/dumps/ に取得するジョブ（本番では毎日04:00にsidekiq-cronで実行）。
  # usersテーブルは個人情報を含むため、スキーマのみでデータは除外する。
  def perform
    FileUtils.mkdir_p(DUMP_DIR)
    path = DUMP_DIR.join("anisonar_#{Time.current.strftime('%Y%m%d%H%M%S')}.dump")
    dump(path)
    rotate
    Rails.logger.info "[DbDumpJob] Done. #{path.basename} (#{File.size(path)} bytes)"
  end

  private

  def dump(path)
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    _stdout, stderr, status = Open3.capture3(
      { "PGPASSWORD" => config[:password].to_s },
      "pg_dump",
      "--format=custom",
      "--no-owner",
      "--exclude-table-data=users",
      "--host", config[:host].to_s,
      "--port", config.fetch(:port, 5432).to_s,
      "--username", config[:username].to_s,
      "--file", path.to_s,
      config[:database].to_s
    )
    raise "pg_dump failed: #{stderr.strip}" unless status.success?
  end

  def rotate
    Dir.glob(DUMP_DIR.join("anisonar_*.dump")).sort.reverse.drop(KEEP_GENERATIONS).each do |old_dump|
      File.delete(old_dump)
      Rails.logger.info "[DbDumpJob] Rotated out #{File.basename(old_dump)}"
    end
  end
end
