require 'rails_helper'

describe AirportsController, type: :controller do
  before :all do
    @user = FactoryGirl.create(:user)
    @destinations = FactoryGirl.create_list(:destination, 60, user: @user)
  end

  before :each do
    request.host = "#{@user.subdomain}.test.host"
  end

  describe "#index" do
    describe ".html" do
      it "should set @lat, @lon to the coordinates of a destination" do
        get :index
        expect(@destinations.detect { |dest| dest.airport.lat == assigns(:lat) && dest.airport.lon == assigns(:lon) }).not_to be_nil
      end

      it "should render the index template" do
        get :index
        expect(response.status).to eql(200)
        expect(response).to render_template('index')
      end
    end

    describe ".json" do
      it "should return the first 50 airports" do
        get :index, format: 'json'
        expect(response.status).to eql(200)
        expect(JSON.parse(response.body).size).to eql(50)
        JSON.parse(response.body).zip(@destinations.sort_by(&:airport_id)[0,50]).each do |(json, dest)|
          expect(json['airport_id']).to eql(dest.airport_id)
          expect(json['photo']).to include(dest.photo.url(:stat))
          expect(json['url']).to match(/\/airports\/#{Regexp.escape dest.airport.identifier}$/)
          [ :name, :city, :state, :identifier, :lat, :lon ].each do |attr|
            expect(json['airport'][attr.to_s]).to eql(dest.airport.send(attr))
          end
        end
      end

      it "should paginate using the last_record parameter" do
        get :index, format: 'json', last_record: @destinations[39].airport_id
        expect(response.status).to eql(200)
        expect(JSON.parse(response.body).size).to eql(20)
        JSON.parse(response.body).zip(@destinations.sort_by(&:airport_id)[40,20]).each do |(json, dest)|
          expect(json['airport_id']).to eql(dest.airport_id)
        end
      end
    end
  end

  describe "#show" do
    it "should return 404 if the airport doesn't exist" do
      get :show, id: 'UNKN'
      expect(response.status).to eql(404)
    end

    it "should return 404 if the airport exists but is not a destination for this user" do
      get :show, id: FactoryGirl.create(:airport).identifier
      expect(response.status).to eql(404)
    end

    context "[valid airport identifier]" do
      before :each do
        @destination = FactoryGirl.create(:destination, user: @user)
      end

      it "should set @destination to the Destination record" do
        get :show, id: @destination.airport.identifier
        expect(assigns(:destination).id).to eql(@destination.id)
      end

      it "should render the show action" do
        get :show, id: @destination.airport.identifier
        expect(response.status).to eql(200)
        expect(response).to render_template('show')
      end
    end
  end
end
