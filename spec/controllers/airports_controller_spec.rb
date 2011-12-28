require 'spec_helper'

describe AirportsController do
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
        @destinations.detect { |dest| dest.airport.lat == assigns(:lat) && dest.airport.lon == assigns(:lon) }.should_not be_nil
      end

      it "should render the index template" do
        get :index
        response.status.should eql(200)
        response.should render_template('index')
      end
    end

    describe ".json" do
      it "should return the first 50 airports" do
        get :index, format: 'json'
        response.status.should eql(200)
        JSON.parse(response.body).size.should eql(50)
        JSON.parse(response.body).zip(@destinations.sort_by(&:airport_id)[0,50]).each do |(json, dest)|
          json['airport_id'].should eql(dest.airport_id)
          json['photo'].should include(dest.photo.url(:stat))
          json['url'].should =~ /\/airports\/#{Regexp.escape dest.airport.identifier}$/
          [ :name, :city, :state, :identifier, :lat, :lon ].each do |attr|
            json['airport'][attr.to_s].should eql(dest.airport.send(attr))
          end
        end
      end

      it "should paginate using the last_record parameter" do
        get :index, format: 'json', last_record: @destinations[39].airport_id
        response.status.should eql(200)
        JSON.parse(response.body).size.should eql(20)
        JSON.parse(response.body).zip(@destinations.sort_by(&:airport_id)[40,20]).each do |(json, dest)|
          json['airport_id'].should eql(dest.airport_id)
        end
      end
    end
  end

  describe "#show" do
    it "should return 404 if the airport doesn't exist" do
      get :show, id: 'UNKN'
      response.status.should eql(404)
    end

    it "should return 404 if the airport exists but is not a destination for this user" do
      get :show, id: FactoryGirl.create(:airport).identifier
      response.status.should eql(404)
    end

    context "[valid airport identifier]" do
      before :each do
        @destination = FactoryGirl.create(:destination, user: @user)
      end

      it "should set @destination to the Destination record" do
        get :show, id: @destination.airport.identifier
        assigns(:destination).id.should eql(@destination.id)
      end

      it "should render the show action" do
        get :show, id: @destination.airport.identifier
        response.status.should eql(200)
        response.should render_template('show')
      end
    end
  end
end
