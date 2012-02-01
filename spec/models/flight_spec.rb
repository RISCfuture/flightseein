require 'spec_helper'

describe Flight do
  describe "#destinations" do
    before :each do
      user = FactoryGirl.create(:user)

      @origin = FactoryGirl.create(:destination, user: user)
      @stop1 = FactoryGirl.create(:destination, user: user)
      @stop2 = FactoryGirl.create(:destination, user: user)
      @stop3 = FactoryGirl.create(:destination, user: user)
      @destination = FactoryGirl.create(:destination, user: user)

      @flight = FactoryGirl.create(:flight, user: user, origin: @origin, destination: @destination)
      FactoryGirl.create :stop, flight: @flight, destination: @stop2, sequence: 2
      FactoryGirl.create :stop, flight: @flight, destination: @stop1, sequence: 1
      FactoryGirl.create :stop, flight: @flight, destination: @stop3, sequence: 3
    end

    it "should return all destinations" do
      @flight.destinations.map(&:airport_id).should eql([ @origin, @stop1, @stop2, @stop3, @destination ].map(&:airport_id))
    end
  end

  describe "#has_blog" do
    it "should be false for flights without a blog" do
      FactoryGirl.create(:flight, blog: nil).should_not have_blog
      FactoryGirl.create(:flight, blog: '').should_not have_blog
    end

    it "should be true for flights with a blog" do
      FactoryGirl.create(:flight, blog: 'foo').should have_blog
    end
  end

  describe "#previous" do
    before :each do
      @flight = FactoryGirl.create(:flight)
    end

    it "should return the previous flight" do
      prev = FactoryGirl.create(:flight, user: @flight.user, date: @flight.date - 1)
      FactoryGirl.create :flight, user: @flight.user, date: @flight.date - 2
      @flight.user.update_flight_sequence!

      @flight.reload.previous.should eql(prev)
    end

    it "should return nil if there is no previous flight" do
      FactoryGirl.create :flight, user: @flight.user, date: @flight.date + 1
      @flight.user.update_flight_sequence!

      @flight.reload.previous.should be_nil
    end

    it "should return nil if the flight is unsequenced" do
      FactoryGirl.create :flight, user: @flight.user, date: @flight.date - 1, sequence: 1
      @flight.reload.previous.should be_nil
    end
  end

  describe "#next" do
    before :each do
      @flight = FactoryGirl.create(:flight)
    end

    it "should return the next flight" do
      prev = FactoryGirl.create(:flight, user: @flight.user, date: @flight.date + 1)
      FactoryGirl.create :flight, user: @flight.user, date: @flight.date + 2
      @flight.user.update_flight_sequence!

      @flight.reload.next.should eql(prev)
    end

    it "should return nil if there is no next flight" do
      FactoryGirl.create :flight, user: @flight.user, date: @flight.date - 1
      @flight.user.update_flight_sequence!

      @flight.reload.next.should be_nil
    end

    it "should return nil if the flight is unsequenced" do
      FactoryGirl.create :flight, user: @flight.user, date: @flight.date + 1, sequence: 1
      @flight.next.should be_nil
    end
  end
end
