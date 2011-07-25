FactoryGirl.define do
  factory :flight do
    association :user
    association :pic, factory: :person

    duration { (rand*5 + 1).round(1) }
    sequence :logbook_id

    origin { |flight| Factory :destination, user: flight.user }
    destination { |flight| Factory :destination, user: flight.user }
    aircraft { |flight| Factory :aircraft, user: flight.user }

    date { Date.today }
    remarks "Test flight"
  end
end
