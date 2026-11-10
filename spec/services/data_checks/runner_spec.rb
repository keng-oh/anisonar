require 'rails_helper'

RSpec.describe DataChecks::Runner do
  def check_class(key, findings: [], error: nil)
    Class.new do
      const_set(:KEY, key)
      define_singleton_method(:call) { error ? raise(error) : findings }
    end
  end

  let(:notifier) { class_double(DataChecks::SummaryNotifier, call: nil) }
  let(:song) { create(:song, title: "曲") }

  it "run・result・finding を記録する" do
    finding = DataChecks::Finding.new(record: song, label: "曲", detail: "理由")
    run = described_class.call(trigger: "manual", checks: [ check_class("a", findings: [ finding ]), check_class("b") ], notifier:)

    expect(run).to be_succeeded
    expect(run).to be_manual
    expect(run.finished_at).to be_present
    expect(run.results.find_by(check_key: "a").findings_count).to eq(1)
    expect(run.results.find_by(check_key: "b").findings_count).to eq(0)
    saved = DataCheckFinding.sole
    expect(saved).to have_attributes(record: song, label: "曲", detail: "理由")
  end

  it "1 項目が例外でも、ほかの項目は記録され、その項目に error_message が入る" do
    finding = DataChecks::Finding.new(record: song, label: "曲", detail: "理由")
    run = described_class.call(trigger: "scheduled", checks: [ check_class("bad", error: "boom"), check_class("ok", findings: [ finding ]) ], notifier:)

    expect(run).to be_succeeded
    bad = run.results.find_by(check_key: "bad")
    expect(bad).to be_failed
    expect(bad.error_message).to include("boom")
    expect(run.results.find_by(check_key: "ok").findings_count).to eq(1)
  end

  it "全項目が失敗したら run を failed にする" do
    run = described_class.call(trigger: "scheduled", checks: [ check_class("bad", error: "boom") ], notifier:)

    expect(run).to be_failed
  end

  it "通知を呼ぶ。通知が失敗しても run は成功のまま" do
    allow(notifier).to receive(:call).and_raise("notify failed")

    run = described_class.call(trigger: "scheduled", checks: [ check_class("a") ], notifier:)

    expect(notifier).to have_received(:call).with(run)
    expect(run.reload).to be_succeeded
  end

  describe "前回からの増減" do
    def run_with_counts(counts, at:)
      run = create(:data_check_run, started_at: at, finished_at: at + 1.minute)
      counts.each { |key, count| run.results.create!(check_key: key, findings_count: count) }
      run
    end

    it "直前に終わった成功した run との差を返す" do
      run_with_counts({ "a" => 5 }, at: 3.days.ago)
      run_with_counts({ "a" => 10 }, at: 2.days.ago)
      create(:data_check_run, status: :failed, started_at: 1.day.ago, finished_at: 1.day.ago + 1.minute)
      current = run_with_counts({ "a" => 12, "b" => 1 }, at: Time.current)

      expect(DataChecks::Delta.for_run(current)).to eq("a" => 2, "b" => nil)
    end

    it "前回が無ければ nil" do
      current = run_with_counts({ "a" => 12 }, at: Time.current)

      expect(DataChecks::Delta.for_run(current)).to eq("a" => nil)
    end

    it "どちらかの項目が失敗していれば nil" do
      previous = run_with_counts({ "a" => 5 }, at: 2.days.ago)
      previous.results.find_by(check_key: "a").update!(error_message: "x")
      current = run_with_counts({ "a" => 12 }, at: Time.current)

      expect(DataChecks::Delta.for_run(current)).to eq("a" => nil)
    end

    it "表示の形" do
      expect([ 3, -2, 0, nil ].map { |d| DataChecks::Delta.format(d) }).to eq([ "+3", "-2", "±0", "—" ])
    end
  end
end
