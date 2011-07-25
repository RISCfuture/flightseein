FactoryGirl.define do
  factory :destination do
    association :user
    association :airport
    sequence :logbook_id
  end
end
