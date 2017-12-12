FactoryBot.define do
  factory :destination do
    association :user
    association :airport
  end
end
