FactoryBot.define do
  factory :data_check_run do
    trigger { :scheduled }
    status { :succeeded }
    started_at { Time.current }
    finished_at { Time.current }
  end
end
