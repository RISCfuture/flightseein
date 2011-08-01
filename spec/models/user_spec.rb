require 'spec_helper'

describe User do
  describe ".authenticated?" do
    it "should return false if the user is nil" do
      User.authenticated?(nil, 'foo').should be_false
    end

    it "should return false if the password is nil" do
      User.authenticated?(FactoryGirl.create(:user), nil).should be_false
    end

    it "should return false if the password doesn't match" do
      User.authenticated?(FactoryGirl.create(:user), 'foo').should be_false
    end

    it "should return true if the password matches" do
      user = FactoryGirl.create(:user)
      User.authenticated?(user, 'password').should be_true
    end
  end

  describe "#authenticated?" do
    it "should return false if the password does not match" do
      FactoryGirl.create(:user).authenticated?('foo').should be_false
    end

    it "should return true if the password matches" do
      FactoryGirl.create(:user).authenticated?('password').should be_true
    end
  end

  describe "#best_name" do
    it "should return the user's name if present" do
      FactoryGirl.create(:user, name: 'Sancho Sample').best_name.should eql('Sancho Sample')
    end

    it "should return the account portion of the user's email otherwise" do
      FactoryGirl.create(:user, name: nil, email: 'sancho@sample.com').best_name.should eql('sancho')
      FactoryGirl.create(:user, name: '', email: 'sancho2@sample.com').best_name.should eql('sancho2')
    end
  end

  describe "#update_flight_sequence!" do
    before :each do
      @user = FactoryGirl.create(:user)
      @flights = 5.times.map { |n| FactoryGirl.create :flight, user: @user, date: Date.today - n }.sort_by(&:date)
      @flights << FactoryGirl.create(:flight, user: @user, date: @flights.last.date)
    end

    it "should sequence the user's flights" do
      FactoryGirl.create :flight, date: Date.today - 10 # red herring to screw up the sequence
      @user.update_flight_sequence!
      @flights.each_with_index { |flight, i| flight.reload.sequence.should eql(i+1) }
    end

    it "should not alter other users' flights" do
      herring = FactoryGirl.create :flight, sequence: 1

      @user.update_flight_sequence!
      @flights.each_with_index { |flight, i| flight.reload.sequence.should eql(i+1) }
      herring.reload.sequence.should eql(1)
    end
  end

  it "should relinquish a subdomain when deleted" do
    user = FactoryGirl.create(:user)
    subdomain = user.subdomain
    user.update_attribute :active, false
    user.subdomain.should_not eql(subdomain)
    user.subdomain.should_not be_blank
  end
end
