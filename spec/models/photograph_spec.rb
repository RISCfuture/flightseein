require 'spec_helper'

describe Photograph do
  context "[save hooks]" do
    it "should set the has_photos attributes of the parent flight to true when saved" do
      flight = Factory(:flight)
      flight.should_not have_photos
      Factory :photograph, flight: flight
      flight.reload.should have_photos
    end
  end
end
