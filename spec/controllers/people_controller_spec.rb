require 'rails_helper'

describe PeopleController, type: :controller do
  before :all do
    @user = FactoryBot.create(:user)
  end

  before :each do
    request.host = "#{@user.subdomain}.test.host"
  end

  describe "#index" do
    describe ".html" do
      it "should render the index template" do
        get :index
        expect(response.status).to eql(200)
        expect(response).to render_template('index')
      end
    end

    describe ".json" do
      before :all do
        @people = FactoryBot.create_list(:person, 60, user: @user)
        @people.each { |pers| FactoryBot.create :passenger, person: pers, flight: FactoryBot.create(:flight, user: @user) }
        @people.each(&:update_hours!)
        @people = @people.sort_by { |pers| [ pers.hours, pers.id ] }.reverse
      end

      it "should return the first 50 people by hours" do
        get :index, params: {format: 'json'}
        expect(response.status).to eql(200)
        expect(JSON.parse(response.body).size).to eql(50)
        JSON.parse(response.body).zip(@people[0, 50]).each do |(json, person)|
          expect(json['id']).to eql(person.id)
          expect(json['name']).to eql(person.name)
          expect(json['hours']).to be_within(0.05).of(person.hours)
          expect(json['url']).to match(/\/people\/#{person.slug}$/)
          expect(json['flights']).to eql(person.flights.count)
          # expect(json['photo']).to include(person.photo.url(:carousel))
        end
      end

      it "should paginate using the last_record parameter" do
        get :index, params: {format: 'json', last_record: @people[49].id}
        expect(response.status).to eql(200)
        expect(JSON.parse(response.body).size).to eql(10)
        JSON.parse(response.body).zip(@people[50, 10]).each do |(json, person)|
          expect(json['id']).to eql(person.id)
        end
      end

      it "should not blow up if given an invalid last_record" do
        get :index, params: {format: 'json', last_record: FactoryBot.create(:person).id}
        expect(response.status).to eql(200)
        expect(JSON.parse(response.body).size).to eql(50)
        JSON.parse(response.body).zip(@people[0, 50]).each do |(json, person)|
          expect(json['id']).to eql(person.id)
        end
      end
    end
  end

  describe "#show" do
    it "should 404 if an invalid flight ID is provided" do
      get :show, params: {id: 'not-found'}
      expect(response.status).to eql(404)
    end

    it "should 404 if the flight does not belong to the subdomain owner" do
      get :show, params: {id: FactoryBot.create(:person).slug}
      expect(response.status).to eql(404)
    end

    context "[valid person]" do
      before :each do
        @person = FactoryBot.create(:person, user: @user)
      end

      it "should set @person to the person" do
        get :show, params: {id: @person.slug}
        expect(assigns(:person)).to eql(@person)
      end

      it "should render the show template" do
        get :show, params: {id: @person.slug}
        expect(response.status).to eql(200)
        expect(response).to render_template('show')
      end
    end
  end
end
