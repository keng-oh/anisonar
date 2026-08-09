FactoryBot.define do
  factory :crawl_request do
    anime

    # anime か anime_series のどちらか一方のみを持てる（DBのcheck制約あり）
    trait :for_series do
      anime { nil }
      anime_series
    end
  end
end
