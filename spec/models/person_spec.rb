require 'spec_helper'

describe Person do
  describe "#update_hours!" do
    it "should update the hours attribute to reflect the total number of hours" do
      user = FactoryGirl.create(:user)
      person = FactoryGirl.create(:person, user: user)
      flights = FactoryGirl.create_list(:flight, 10, user: user)
      flights.each { |flight| person.flights << flight }

      person.update_hours!

      person.hours.should eql(flights.map(&:duration).sum.round(1))
    end
  end

  describe "#to_param" do
    it "should slug the person's name" do
      FactoryGirl.create(:person, name: "Sancho Sample").to_param.should eql('Sancho_Sample')
      FactoryGirl.create(:person, name: "Buford T. Justice").to_param.should eql('Buford_T_Justice')
    end
  end
end
