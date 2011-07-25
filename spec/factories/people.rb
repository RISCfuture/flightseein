FactoryGirl.define do
  factory :person do
    association :user
    name { Faker::Name.name }
    sequence :logbook_id
  end
end
