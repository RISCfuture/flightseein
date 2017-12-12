require 'rails_helper'

describe Photograph, type: :model do
  context "[save hooks]" do
    it "should set the has_photos attributes of the parent flight to true when saved" do
      flight = FactoryBot.create(:flight)
      expect(flight).not_to have_photos
      FactoryBot.create :photograph, flight: flight
      expect(flight.reload).to have_photos
    end
  end
end
