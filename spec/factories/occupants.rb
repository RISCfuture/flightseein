FactoryBot.define do
  factory :passenger, class: Occupant do
    association :person
    association :flight
  end

  factory :crewmember, parent: :passenger do
    role "Pilot in command"
  end
end
