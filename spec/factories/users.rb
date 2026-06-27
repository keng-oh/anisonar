FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    role { :general }
    trusted_count { 0 }
    confirmed_at { Time.current }

    trait :reviewer do
      role { :reviewer }
    end

    trait :admin do
      role { :admin }
    end

    trait :trusted do
      trusted_count { 10 }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
