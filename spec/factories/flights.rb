FactoryGirl.define do
  factory :flight do
    association :user

    duration { (rand*5 + 1).round(1) }
    sequence :logbook_id

    origin { |flight| FactoryGirl.create :destination, user: flight.user }
    destination { |flight| FactoryGirl.create :destination, user: flight.user }
    aircraft { |flight| FactoryGirl.create :aircraft, user: flight.user }

    date { Date.today }
    remarks "Test flight"
  end
end
