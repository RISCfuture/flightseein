require 'rails_helper'

describe Person, type: :model do
  describe "#update_hours!" do
    it "should update the hours attribute to reflect the total number of hours" do
      user = FactoryGirl.create(:user)
      person = FactoryGirl.create(:person, user: user)
      flights = FactoryGirl.create_list(:flight, 10, user: user)
      flights.each { |flight| FactoryGirl.create :passenger, flight: flight, person: person }

      person.update_hours!

      expect(person.hours).to eql(flights.map(&:duration).sum.round(1))
    end
  end

  describe "#to_param" do
    it "should slug the person's name" do
      expect(FactoryGirl.create(:person, name: "Sancho Sample").to_param).to eql('Sancho_Sample')
      expect(FactoryGirl.create(:person, name: "Buford T. Justice").to_param).to eql('Buford_T_Justice')
    end
  end
end
