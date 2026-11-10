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
end
