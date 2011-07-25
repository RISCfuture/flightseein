FactoryGirl.define do
  factory :aircraft do
    association :user
    
    sequence(:ident) { |i| "N#{i.to_s.rjust(5, '0')}" }
    year { rand(Date.today.year - 1970) + 1970 }
    type { %w( C152 C172 C182 PA28 7ECA ).sample }
    long_type do |f|
      {
        'C152' => 'Cessna 152',
        'C172' => 'Cessna 172 Skyhawk',
        'C182' => 'Cessna 182 Skylane',
        'PA28' => 'Piper PA-28 Cherokee Arrow',
        '7ECA' => 'Bellanca Citabria'
      }[f.type]
    end
  end
end
