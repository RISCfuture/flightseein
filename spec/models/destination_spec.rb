require 'spec_helper'

describe Destination do
  describe "#update_flights_count!" do
    it "should set flights_count to the number of originating flights + terminating flights + enroute stops" do
      dest = Factory(:destination)

      2.times { Factory :flight, user: dest.user, origin: dest }
      dest.update_flights_count!
      dest.flights_count.should eql(2)

      3.times { Factory :flight, user: dest.user, destination: dest }
      dest.update_flights_count!
      dest.flights_count.should eql(5)

      2.times do
        flight = Factory :flight, user: dest.user
        Factory :stop, flight: flight, destination: dest, sequence: 1
      end
      dest.update_flights_count!
      dest.flights_count.should eql(7)
    end
  end
end
