require 'rails_helper'

RSpec.describe PlatformLinkAttempt, type: :model do
  subject { song.platform_link_attempts.build(platform: :spotify, last_attempted_at: Time.current, next_attempt_at: 1.day.from_now) }

  let(:song) { Song.create!(title: "曲", artist: create(:artist)) }

  it { is_expected.to belong_to(:song) }
  it { is_expected.to validate_presence_of(:platform) }
  it { is_expected.to validate_uniqueness_of(:platform).scoped_to(:song_id).ignoring_case_sensitivity }

  describe ".due" do
    it "次に照合する時期が来たものだけを返す" do
      due = song.platform_link_attempts.create!(platform: :spotify, last_attempted_at: 1.day.ago, next_attempt_at: 1.minute.ago)
      Song.create!(title: "別の曲", artist: song.artist)
          .platform_link_attempts.create!(platform: :spotify, last_attempted_at: Time.current, next_attempt_at: 1.day.from_now)

      expect(described_class.due).to contain_exactly(due)
    end
  end
end
