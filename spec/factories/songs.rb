FactoryBot.define do
  factory :song do
    sequence(:title) { |n| "楽曲#{n}" }
    artist
  end

  factory :anime_song do
    anime
    song
    song_type { :op }
  end

  factory :series_song do
    anime_series
    song
    song_type { :op }
  end

  factory :platform_link do
    song
    platform { :spotify }
    sequence(:platform_track_id) { |n| "track#{n}" }
  end

  factory :platform_link_attempt do
    song
    platform { :spotify }
    last_attempted_at { Time.current }
    next_attempt_at { 1.day.from_now }
  end
end
