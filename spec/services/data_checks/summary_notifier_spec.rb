require 'rails_helper'

RSpec.describe DataChecks::SummaryNotifier do
  let(:ntfy) { instance_double(Notifications::Channels::Ntfy, notify: nil) }
  let(:discord) { instance_double(Notifications::Channels::Discord, notify: nil) }

  it "項目ごとの件数と増減を、エラー通知と区別できるタイトルで送る" do
    previous = create(:data_check_run, started_at: 7.days.ago, finished_at: 7.days.ago + 1.minute)
    previous.results.create!(check_key: DataChecks::DuplicateSongTitles::KEY, findings_count: 9)
    run = create(:data_check_run, started_at: Time.zone.local(2026, 11, 9, 7, 0), finished_at: Time.zone.local(2026, 11, 9, 7, 1))
    run.results.create!(check_key: DataChecks::DuplicateSongTitles::KEY, findings_count: 12)
    run.results.create!(check_key: DataChecks::CrawlFailures::KEY, findings_count: 0)
    run.results.create!(check_key: DataChecks::NoisySongTitles::KEY, error_message: "boom")

    described_class.call(run, ntfy:, discord:)

    expected = [ "データの点検（2026-11-09）", "曲名の重複: 12件（+3）", "クロールの失敗: 0件（—）", "曲名の混入物: 失敗", "http://example.com/admin/data_checks" ].join("\n")
    expect(ntfy).to have_received(:notify).with(expected, title: "Anisonar データの点検", priority: "default")
    expect(discord).to have_received(:notify).with(expected, title: "Anisonar データの点検")
  end
end
