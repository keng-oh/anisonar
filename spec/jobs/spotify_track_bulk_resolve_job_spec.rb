require 'rails_helper'

RSpec.describe SpotifyTrackBulkResolveJob do
  include ActiveJob::TestHelper

  let(:artist) { create(:artist) }

  def song(title) = Song.create!(title: title, artist: artist)

  def not_found(song, next_attempt_at:)
    song.platform_link_attempts.create!(platform: :spotify, attempts_count: 1, last_attempted_at: 1.day.ago, next_attempt_at: next_attempt_at)
  end

  it "未連携の曲のうち、未試行の曲と再照合の時期が来た曲を照合する" do
    untried = song("未試行")
    due = song("再照合").tap { |s| not_found(s, next_attempt_at: 1.minute.ago) }
    song("まだ待つ").tap { |s| not_found(s, next_attempt_at: 1.day.from_now) }
    song("連携済み").platform_links.create!(platform: :spotify, platform_track_id: "t1")

    described_class.perform_now

    enqueued = enqueued_jobs.select { |j| j["job_class"] == "SpotifyTrackResolveJob" }.map { |j| j["arguments"].first }
    expect(enqueued).to contain_exactly(untried.id, due.id)
  end

  it "未試行の曲を優先し、件数の上限を超えて照合しない" do
    stub_const("#{described_class}::BATCH_SIZE", 2)
    due = song("再照合").tap { |s| not_found(s, next_attempt_at: 1.minute.ago) }
    untried = [ song("未試行1"), song("未試行2") ]

    described_class.perform_now

    enqueued = enqueued_jobs.map { |j| j["arguments"].first }
    expect(enqueued).to eq(untried.map(&:id))
    expect(enqueued).not_to include(due.id)
  end

  it "Spotify のレート制限中は何も積まない" do
    song("未試行")
    allow(Spotify::Client).to receive(:rate_limited_until).and_return(1.hour.from_now)

    described_class.perform_now

    expect(enqueued_jobs).to be_empty
  end
end
