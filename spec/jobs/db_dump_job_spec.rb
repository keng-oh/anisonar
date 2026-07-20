require 'rails_helper'

RSpec.describe DbDumpJob, type: :job do
  let(:dump_dir) { Pathname(Dir.mktmpdir) }

  before { stub_const("DbDumpJob::DUMP_DIR", dump_dir) }
  after { FileUtils.remove_entry(dump_dir) }

  def stub_pg_dump(success: true)
    executed_args = []
    allow(Open3).to receive(:capture3) do |_env, *args|
      executed_args.concat(args)
      FileUtils.touch(args[args.index("--file") + 1]) if success
      [ "", success ? "" : "connection refused", instance_double(Process::Status, success?: success) ]
    end
    executed_args
  end

  describe "#perform" do
    it "creates a dump file" do
      stub_pg_dump
      described_class.perform_now
      expect(dump_dir.glob("anisonar_*.dump").size).to eq(1)
    end

    it "excludes users table data" do
      args = stub_pg_dump
      described_class.perform_now
      expect(args).to include("--exclude-table-data=users")
      expect(args).to include("--format=custom")
    end

    it "keeps only the latest #{DbDumpJob::KEEP_GENERATIONS} dumps" do
      %w[20260101040000 20260102040000 20260103040000].each do |ts|
        FileUtils.touch(dump_dir.join("anisonar_#{ts}.dump"))
      end
      stub_pg_dump
      described_class.perform_now

      remaining = dump_dir.glob("anisonar_*.dump").map { |f| f.basename.to_s }
      expect(remaining.size).to eq(DbDumpJob::KEEP_GENERATIONS)
      expect(remaining).not_to include("anisonar_20260101040000.dump")
    end

    it "raises when pg_dump fails" do
      stub_pg_dump(success: false)
      expect { described_class.perform_now }.to raise_error(/pg_dump failed: connection refused/)
    end
  end
end
