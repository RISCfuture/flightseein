require 'spec_helper'

describe Flight do
  describe "#destinations" do
    before :each do
      user = Factory(:user)

      @origin = Factory(:destination, user: user)
      @stop1 = Factory(:destination, user: user)
      @stop2 = Factory(:destination, user: user)
      @stop3 = Factory(:destination, user: user)
      @destination = Factory(:destination, user: user)

      @flight = Factory(:flight, user: user, origin: @origin, destination: @destination)
      Factory :stop, flight: @flight, destination: @stop2, sequence: 2
      Factory :stop, flight: @flight, destination: @stop1, sequence: 1
      Factory :stop, flight: @flight, destination: @stop3, sequence: 3
    end

    it "should return all destinations" do
      @flight.destinations.map(&:airport_id).should eql([ @origin, @stop1, @stop2, @stop3, @destination ].map(&:airport_id))
    end
  end

  describe "#has_blog" do
    it "should be false for flights without a blog" do
      Factory(:flight, blog: nil).should_not have_blog
      Factory(:flight, blog: '').should_not have_blog
    end

    it "should be true for flights with a blog" do
      Factory(:flight, blog: 'foo').should have_blog
    end
  end

  describe "#update_people!" do
    it "should automatically add the PIC" do
      flight = Factory(:flight)
      flight.people.should include(flight.pic)
    end

    it "should automatically add the SIC" do
      user = Factory(:user)
      flight = Factory(:flight, user: user, sic: Factory(:person, user: user))
      flight.people.should include(flight.sic)
    end

    it "should not call update_people! unless the PIC or SIC is changed" do
      flight = Factory(:flight)
      flight.should_not_receive(:update_people!)
      flight.blog = "hello!"
      flight.save!
    end

    it "should automatically add the passengers" do
      flight = Factory(:flight)
      flight.passengers << Factory(:person, user: flight.user)
      flight.passengers << Factory(:person, user: flight.user)
      flight.update_people!
      flight.passengers.each { |pax| flight.people.should include(pax) }
    end
  end
end
