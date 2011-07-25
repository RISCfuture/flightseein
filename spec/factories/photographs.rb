FactoryGirl.define do
  factory :photograph do
    association :flight
    caption "Looking eastward over the valley."
    image { open Rails.root.join('spec', 'fixtures', 'image.jpg') }
  end
end
