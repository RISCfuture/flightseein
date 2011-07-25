require 'spec_helper'

describe Person do
  describe "#update_hours!" do
    it "should update the hours attribute to reflect the total number of hours" do
      user = Factory(:user)
      person = Factory(:person, user: user)
      flights = (1..10).map { Factory :flight, user: user }
      flights.each { |flight| person.flights << flight }

      person.update_hours!

      person.hours.should eql(flights.map(&:duration).sum.round(1))
    end
  end

  describe "#to_param" do
    it "should slug the person's name" do
      Factory(:person, name: "Sancho Sample").to_param.should eql('Sancho_Sample')
      Factory(:person, name: "Buford T. Justice").to_param.should eql('Buford_T_Justice')
    end
  end
end
