FactoryBot.define do
  factory :photograph do
    association :flight
    caption "Looking eastward over the valley."
    image { Rack::Test::UploadedFile.new Rails.root.join('spec', 'fixtures', 'image.jpg'), 'image/jpeg' }
  end
end
