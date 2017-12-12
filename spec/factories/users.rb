FactoryBot.define do
  factory :user do
    sequence(:email) { |i| "email-#{i}@example.com" }
    sequence(:subdomain) { |i| "test#{i}" }
    password "password"
    name { Faker::Name.name }
    quote "For I have slipped the surly bonds of earth..."
  end
end
