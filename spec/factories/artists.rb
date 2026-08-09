FactoryBot.define do
  factory :artist do
    sequence(:name) { |n| "アーティスト#{n}" }
    artist_type { :person }
  end
end
