require 'spec_helper'

describe PhotographsController do
  context "[nested under flights]" do
    before :all do
      @user = FactoryGirl.create(:user)
    end

    before :each do
      request.host = "#{@user.subdomain}.test.host"
    end

    describe "#index" do
      before :all do
        @flight = FactoryGirl.create(:flight, user: @user)
        @photographs = FactoryGirl.create_list(:photograph, 15, flight: @flight).sort_by(&:id)
      end

      it "should return the first 50 photos by hours" do
        get :index, flight_id: @flight.to_param, format: 'json'
        response.status.should eql(200)
        JSON.parse(response.body).size.should eql(10)
        JSON.parse(response.body).zip(@photographs[0, 10]).each do |(json, photo)|
          json['id'].should eql(photo.id)
          json['url'].should eql(photo.image.url)
          json['preview_url'].should eql(photo.image.url(:carousel))
          json['caption'].should eql(photo.caption)
        end
      end

      it "should paginate using the last_record parameter" do
        get :index, flight_id: @flight.to_param, format: 'json', last_record: @photographs[9].id
        response.status.should eql(200)
        JSON.parse(response.body).size.should eql(5)
        JSON.parse(response.body).zip(@photographs[10, 5]).each do |(json, photo)|
          json['id'].should eql(photo.id)
        end
      end

      it "should not blow up if given an invalid last_record" do
        get :index, flight_id: @flight.to_param, format: 'json', last_record: 'abc'
        response.status.should eql(200)
        JSON.parse(response.body).size.should eql(10)
        JSON.parse(response.body).zip(@photographs[0, 10]).each do |(json, photo)|
          json['id'].should eql(photo.id)
        end
      end
    end

    describe "#create" do
      before :all do
        @flight = FactoryGirl.create(:flight, user: @user)
      end

      it "should create a photograph from the 'photograph' parameter hash" do
        post :create, flight_id: @flight.to_param, photograph: { image: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'image.jpg'), 'image/jpeg') }, format: 'json'
        response.status.should eql(201)
        @flight.photographs(true).size.should eql(1)
        @flight.photographs.first.image_file_name.should eql('image.jpg')
      end

      it "should encode errors in the JSON response" do
        pending "Thanks Rails 3.2, for breaking this one!"
        post :create, flight_id: @flight.to_param, photograph: { image: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'bogus.txt'), 'text/plain') }, format: 'json'
        response.status.should eql(422)
        JSON.parse(response.body).should eql('image_content_type' => [ 'must be an image file (such as JPEG)' ])
      end
    end
  end

  context "[top level]" do
    describe "#index" do
      describe ".json" do
        before :all do
          Flight.delete_all
          @flights = 10.times.map { |i| FactoryGirl.create(:flight, date: Date.today - i ) }.sort_by(&:date).reverse
          @flights.each { |flight| FactoryGirl.create_list :photograph, 5, flight: flight }
          5.times.map { |i| FactoryGirl.create :flight, date: Date.today - i }
        end
  
        it "should return photographs from the 10 most recent flights with photos" do
          get :index, format: 'json'
          response.status.should eql(200)
          JSON.parse(response.body).size.should eql(5)
          JSON.parse(response.body).zip(@flights[0, 5]).each do |(json, flight)|
            flight.photographs.detect do |photo|
              json['preview_url'] == photo.image.url(:carousel) &&
                json['caption'] == photo.caption
            end.should_not be_nil
            json['url'].should =~ /\/flights\/#{flight.to_param}/
          end
        end

        it "should ignore the last_record parameter" do
          get :index, format: 'json', last_record: '100'
          response.status.should eql(200)
          JSON.parse(response.body).size.should eql(5)
        end
      end
    end
  end
end
