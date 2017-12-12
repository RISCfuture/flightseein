require 'rails_helper'

describe User, type: :model do
  describe ".authenticated?" do
    it "should return false if the user is nil" do
      expect(User.authenticated?(nil, 'foo')).to be(false)
    end

    it "should return false if the password is nil" do
      expect(User.authenticated?(FactoryBot.create(:user), nil)).to be(false)
    end

    it "should return false if the password doesn't match" do
      expect(User.authenticated?(FactoryBot.create(:user), 'foo')).to be(false)
    end

    it "should return true if the password matches" do
      user = FactoryBot.create(:user)
      expect(User.authenticated?(user, 'password')).to be(true)
    end
  end

  describe "#authenticated?" do
    it "should return false if the password does not match" do
      expect(FactoryBot.create(:user).authenticated?('foo')).to be(false)
    end

    it "should return true if the password matches" do
      expect(FactoryBot.create(:user).authenticated?('password')).to be(true)
    end
  end

  describe "#best_name" do
    it "should return the user's name if present" do
      expect(FactoryBot.create(:user, name: 'Sancho Sample').best_name).to eql('Sancho Sample')
    end

    it "should return the account portion of the user's email otherwise" do
      expect(FactoryBot.create(:user, name: nil, email: 'sancho@sample.com').best_name).to eql('sancho')
      expect(FactoryBot.create(:user, name: '', email: 'sancho2@sample.com').best_name).to eql('sancho2')
    end
  end

  describe "#update_flight_sequence!" do
    before :each do
      @user = FactoryBot.create(:user)
      @flights = Array.new(5) { |n| FactoryBot.create :flight, user: @user, date: Date.today - n }.sort_by(&:date)
      @flights << FactoryBot.create(:flight, user: @user, date: @flights.last.date)
    end

    it "should sequence the user's flights" do
      FactoryBot.create :flight, date: Date.today - 10 # red herring to screw up the sequence
      @user.update_flight_sequence!
      @flights.each_with_index { |flight, i| expect(flight.reload.sequence).to eql(i+1) }
    end

    it "should not alter other users' flights" do
      herring = FactoryBot.create :flight, sequence: 1

      @user.update_flight_sequence!
      @flights.each_with_index { |flight, i| expect(flight.reload.sequence).to eql(i+1) }
      expect(herring.reload.sequence).to eql(1)
    end
  end

  it "should relinquish a subdomain when deleted" do
    user = FactoryBot.create(:user)
    subdomain = user.subdomain
    user.update_attribute :active, false
    expect(user.subdomain).not_to eql(subdomain)
    expect(user.subdomain).not_to be_blank
  end
end
