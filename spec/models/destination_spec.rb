require 'spec_helper'

describe Destination, type: :model do
  describe "#update_flights_count!" do
    it "should set flights_count to the number of originating flights + terminating flights + enroute stops" do
      dest = FactoryGirl.create(:destination)

      FactoryGirl.create_list :flight, 2, user: dest.user, origin: dest
      dest.update_flights_count!
      expect(dest.flights_count).to eql(2)

      FactoryGirl.create_list :flight, 3, user: dest.user, destination: dest
      dest.update_flights_count!
      expect(dest.flights_count).to eql(5)

      2.times do
        flight = FactoryGirl.create :flight, user: dest.user
        FactoryGirl.create :stop, flight: flight, destination: dest, sequence: 1
      end
      dest.update_flights_count!
      expect(dest.flights_count).to eql(7)
    end
  end
end
