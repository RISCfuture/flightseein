require 'rails_helper'

describe Flight, type: :model do
  describe "#destinations" do
    before :each do
      user = FactoryBot.create(:user)

      @origin = FactoryBot.create(:destination, user: user)
      @stop1 = FactoryBot.create(:destination, user: user)
      @stop2 = FactoryBot.create(:destination, user: user)
      @stop3 = FactoryBot.create(:destination, user: user)
      @destination = FactoryBot.create(:destination, user: user)

      @flight = FactoryBot.create(:flight, user: user, origin: @origin, destination: @destination)
      FactoryBot.create :stop, flight: @flight, destination: @stop2, sequence: 2
      FactoryBot.create :stop, flight: @flight, destination: @stop1, sequence: 1
      FactoryBot.create :stop, flight: @flight, destination: @stop3, sequence: 3
    end

    it "should return all destinations" do
      expect(@flight.destinations.map(&:airport_id)).to eql([ @origin, @stop1, @stop2, @stop3, @destination ].map(&:airport_id))
    end
  end

  describe "#has_blog" do
    it "should be false for flights without a blog" do
      expect(FactoryBot.create(:flight, blog: nil)).not_to have_blog
      expect(FactoryBot.create(:flight, blog: '')).not_to have_blog
    end

    it "should be true for flights with a blog" do
      expect(FactoryBot.create(:flight, blog: 'foo')).to have_blog
    end
  end

  describe "#previous" do
    before :each do
      @flight = FactoryBot.create(:flight)
    end

    it "should return the previous flight" do
      prev = FactoryBot.create(:flight, user: @flight.user, date: @flight.date - 1)
      FactoryBot.create :flight, user: @flight.user, date: @flight.date - 2
      @flight.user.update_flight_sequence!

      expect(@flight.reload.previous).to eql(prev)
    end

    it "should return nil if there is no previous flight" do
      FactoryBot.create :flight, user: @flight.user, date: @flight.date + 1
      @flight.user.update_flight_sequence!

      expect(@flight.reload.previous).to be_nil
    end

    it "should return nil if the flight is unsequenced" do
      FactoryBot.create :flight, user: @flight.user, date: @flight.date - 1, sequence: 1
      expect(@flight.reload.previous).to be_nil
    end
  end

  describe "#next" do
    before :each do
      @flight = FactoryBot.create(:flight)
    end

    it "should return the next flight" do
      prev = FactoryBot.create(:flight, user: @flight.user, date: @flight.date + 1)
      FactoryBot.create :flight, user: @flight.user, date: @flight.date + 2
      @flight.user.update_flight_sequence!

      expect(@flight.reload.next).to eql(prev)
    end

    it "should return nil if there is no next flight" do
      FactoryBot.create :flight, user: @flight.user, date: @flight.date - 1
      @flight.user.update_flight_sequence!

      expect(@flight.reload.next).to be_nil
    end

    it "should return nil if the flight is unsequenced" do
      FactoryBot.create :flight, user: @flight.user, date: @flight.date + 1, sequence: 1
      expect(@flight.next).to be_nil
    end
  end
end
