FactoryBot.define do
  factory :anime_series do
    sequence(:name) { |n| "シリーズ#{n}" }
  end

  factory :anime do
    sequence(:title) { |n| "アニメ#{n}" }
  end
end
