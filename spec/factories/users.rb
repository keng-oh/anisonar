FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    role { :general }
    confirmed_at { Time.current }

    trait :reviewer do
      role { :reviewer }
    end

    trait :admin do
      role { :admin }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
