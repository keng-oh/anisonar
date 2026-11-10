require 'rails_helper'

RSpec.describe DataCheckJob, type: :job do
  before { allow(DataChecks::Runner).to receive(:call) }

  it "Runner を呼ぶ" do
    described_class.perform_now("manual")

    expect(DataChecks::Runner).to have_received(:call).with(trigger: "manual")
  end

  it "既定のきっかけは scheduled" do
    described_class.perform_now

    expect(DataChecks::Runner).to have_received(:call).with(trigger: "scheduled")
  end

  it "1 時間以内に始まった running があればスキップする" do
    create(:data_check_run, status: :running, started_at: 10.minutes.ago, finished_at: nil)

    described_class.perform_now

    expect(DataChecks::Runner).not_to have_received(:call)
  end

  it "1 時間より古い running は落ちたものとみなして無視する" do
    create(:data_check_run, status: :running, started_at: 2.hours.ago, finished_at: nil)

    described_class.perform_now

    expect(DataChecks::Runner).to have_received(:call)
  end
end
