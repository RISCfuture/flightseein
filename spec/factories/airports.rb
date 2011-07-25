FactoryGirl.define do
  factory :airport do
    sequence(:site_number) { |i| "A#{i.to_s.rjust(5, '0')}" }
    sequence(:lid) { |i| i.to_s(36).rjust(4, '0').upcase[0,4] }
    name "Example Airport Int'l"
    city "Example"
    state "CA"
    lat { rand*180.0 - 90.0 }
    lon { rand*360.0 - 90.0 }
  end
end
