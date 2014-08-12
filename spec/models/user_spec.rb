require 'spec_helper'

describe User, type: :model do
  describe ".authenticated?" do
    it "should return false if the user is nil" do
      expect(User.authenticated?(nil, 'foo')).to be(false)
    end

    it "should return false if the password is nil" do
      expect(User.authenticated?(FactoryGirl.create(:user), nil)).to be(false)
    end

    it "should return false if the password doesn't match" do
      expect(User.authenticated?(FactoryGirl.create(:user), 'foo')).to be(false)
    end

    it "should return true if the password matches" do
      user = FactoryGirl.create(:user)
      expect(User.authenticated?(user, 'password')).to be(true)
    end
  end

  describe "#authenticated?" do
    it "should return false if the password does not match" do
      expect(FactoryGirl.create(:user).authenticated?('foo')).to be(false)
    end

    it "should return true if the password matches" do
      expect(FactoryGirl.create(:user).authenticated?('password')).to be(true)
    end
  end

  describe "#best_name" do
    it "should return the user's name if present" do
      expect(FactoryGirl.create(:user, name: 'Sancho Sample').best_name).to eql('Sancho Sample')
    end

    it "should return the account portion of the user's email otherwise" do
      expect(FactoryGirl.create(:user, name: nil, email: 'sancho@sample.com').best_name).to eql('sancho')
      expect(FactoryGirl.create(:user, name: '', email: 'sancho2@sample.com').best_name).to eql('sancho2')
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
      @flights.each_with_index { |flight, i| expect(flight.reload.sequence).to eql(i+1) }
    end

    it "should not alter other users' flights" do
      herring = FactoryGirl.create :flight, sequence: 1

      @user.update_flight_sequence!
      @flights.each_with_index { |flight, i| expect(flight.reload.sequence).to eql(i+1) }
      expect(herring.reload.sequence).to eql(1)
    end
  end

  it "should relinquish a subdomain when deleted" do
    user = FactoryGirl.create(:user)
    subdomain = user.subdomain
    user.update_attribute :active, false
    expect(user.subdomain).not_to eql(subdomain)
    expect(user.subdomain).not_to be_blank
  end
end
