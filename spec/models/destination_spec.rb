require 'rails_helper'

describe Destination, type: :model do
  describe "#update_flights_count!" do
    it "should set flights_count to the number of originating flights + terminating flights + enroute stops" do
      dest = FactoryBot.create(:destination)

      FactoryBot.create_list :flight, 2, user: dest.user, origin: dest
      dest.update_flights_count!
      expect(dest.flights_count).to eql(2)

      FactoryBot.create_list :flight, 3, user: dest.user, destination: dest
      dest.update_flights_count!
      expect(dest.flights_count).to eql(5)

      2.times do
        flight = FactoryBot.create :flight, user: dest.user
        FactoryBot.create :stop, flight: flight, destination: dest, sequence: 1
      end
      dest.update_flights_count!
      expect(dest.flights_count).to eql(7)
    end
  end
end
