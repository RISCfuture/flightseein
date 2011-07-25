FactoryGirl.define do
  factory :stop do
    association :destination
    association :flight
  end
end
