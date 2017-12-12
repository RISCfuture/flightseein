require 'rails_helper'

describe PhotographsController, type: :controller do
  context "[nested under flights]" do
    before :all do
      @user = FactoryBot.create(:user)
    end

    before :each do
      request.host = "#{@user.subdomain}.test.host"
    end

    describe "#index" do
      before :all do
        @flight      = FactoryBot.create(:flight, user: @user)
        @photographs = FactoryBot.create_list(:photograph, 15, flight: @flight).sort_by(&:id)
      end

      it "should return the first 50 photos by hours" do
        get :index, params: {flight_id: @flight.to_param, format: 'json'}
        expect(response.status).to eql(200)
        expect(JSON.parse(response.body).size).to eql(10)
        JSON.parse(response.body).zip(@photographs[0, 10]).each do |(json, photo)|
          expect(json['id']).to eql(photo.id)
          expect(json['url']).to eql(photo.image.url)
          expect(json['preview_url']).to eql(photo.image.url(:carousel))
          expect(json['caption']).to eql(photo.caption)
        end
      end

      it "should paginate using the last_record parameter" do
        get :index, params: {flight_id: @flight.to_param, format: 'json', last_record: @photographs[9].id}
        expect(response.status).to eql(200)
        expect(JSON.parse(response.body).size).to eql(5)
        JSON.parse(response.body).zip(@photographs[10, 5]).each do |(json, photo)|
          expect(json['id']).to eql(photo.id)
        end
      end

      it "should not blow up if given an invalid last_record" do
        get :index, params: {flight_id: @flight.to_param, format: 'json', last_record: 'abc'}
        expect(response.status).to eql(200)
        expect(JSON.parse(response.body).size).to eql(10)
        JSON.parse(response.body).zip(@photographs[0, 10]).each do |(json, photo)|
          expect(json['id']).to eql(photo.id)
        end
      end
    end

    describe "#create" do
      before :all do
        @flight = FactoryBot.create(:flight, user: @user)
      end

      it "should create a photograph from the 'photograph' parameter hash" do
        post :create, params: {flight_id: @flight.to_param, photograph: { image: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'image.jpg'), 'image/jpeg') }, format: 'json'}
        expect(response.status).to eql(201)
        expect(@flight.photographs.reload.size).to eql(1)
        expect(@flight.photographs.first.image_file_name).to eql('image.jpg')
      end

      it "should encode errors in the JSON response" do
        post :create, params: {flight_id: @flight.to_param, photograph: { image: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'bogus.txt'), 'text/plain') }, format: 'json'}
        expect(response.status).to eql(422)
        expect(JSON.parse(response.body)['errors']['image_content_type']).to eql(['must be an image file (such as JPEG)'])
      end
    end
  end

  context "[top level]" do
    describe "#index" do
      describe ".json" do
        before :all do
          Flight.delete_all
          @flights = Array.new(10) { |i| FactoryBot.create(:flight, date: Date.today - i) }.sort_by(&:date).reverse
          @flights.each { |flight| FactoryBot.create_list :photograph, 5, flight: flight }
          Array.new(5) { |i| FactoryBot.create :flight, date: Date.today - i }
        end

        it "should return photographs from the 10 most recent flights with photos" do
          get :index, params: {format: 'json'}
          expect(response.status).to eql(200)
          expect(JSON.parse(response.body).size).to eql(5)
          JSON.parse(response.body).zip(@flights[0, 5]).each do |(json, flight)|
            expect(flight.photographs.detect do |photo|
              json['preview_url'] == photo.image.url(:carousel) &&
                  json['caption'] == photo.caption
            end).not_to be_nil
            expect(json['url']).to match(/\/flights\/#{flight.to_param}/)
          end
        end

        it "should ignore the last_record parameter" do
          get :index, params: {format: 'json', last_record: '100'}
          expect(response.status).to eql(200)
          expect(JSON.parse(response.body).size).to eql(5)
        end
      end
    end
  end
end
