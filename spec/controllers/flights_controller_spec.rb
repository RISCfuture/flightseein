require 'rails_helper'

describe FlightsController, type: :controller do
  before :all do
    @user = FactoryGirl.create(:user)
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
      describe "[basic route]" do
        before :all do
          Flight.delete_all
          @blog_flights = 60.times.map { FactoryGirl.create :flight, user: @user, blog: "Hello, world!", date: Date.today - rand(600) }
          noblog_flights = 60.times.map { FactoryGirl.create :flight, user: @user, blog: nil, date: Date.today - rand(600) }
          @user.update_flight_sequence!
          @blog_flights = Flight.where(id: @blog_flights.map(&:id)).order('sequence DESC')
          @flights = Flight.where(id: (@blog_flights + noblog_flights).map(&:id)).order('sequence DESC')

          100.times { FactoryGirl.create :photograph, flight: @flights.sample }
          50.times { FactoryGirl.create :passenger, flight: @flights.sample, person: FactoryGirl.create(:person, user: @user) }
        end

        it "should use filter=all by default" do
          get :index, params: {format: 'json'}
          expect(response.status).to eql(200)
          expect(JSON.parse(response.body).map { |hsh| hsh['id'] }).to eql(@flights[0, 50].map(&:sequence))
        end

        context "[filter = all]" do
          it "should return the first 50 flights by date" do
            get :index, params: {format: 'json', filter: 'all'}
            expect(response.status).to eql(200)
            expect(JSON.parse(response.body).size).to eql(50)
            JSON.parse(response.body).zip(@flights[0, 50]).each do |(json, flight)|
              [ :remarks, :duration ].each do |attr|
                expect(json[attr.to_s]).to eql(flight.send(attr))
              end
              expect(json['id']).to eql(flight.sequence)
              [ :type, :ident ].each do |attr|
                expect(json['aircraft'][attr.to_s]).to eql(flight.aircraft.send(attr))
              end
              expect(json['url']).to match(/\/flights\/#{flight.to_param}$/)
              expect(json['date']).to eql(I18n.l(flight.date, format: :logbook))
              expect(json['photos'].size).to be <= 4
              json['photos'].each do |attrs|
                expect(flight.photographs.detect do |photo|
                  attrs['thumbnail'] == photo.image.url(:logbook) &&
                    attrs['full'] == photo.image.url &&
                    attrs['caption'] == photo.caption
                end).not_to be_nil
              end
              expect(json['occupants'].size).to eql(flight.occupants.count)
              json['occupants'].each do |attrs|
                expect(flight.occupants.map(&:person).detect do |person|
                  attrs['name'] == person.name &&
                    attrs['url'] =~ /\/people\/#{Regexp.escape person.slug}$/ &&
                    attrs['photo'].include?(person.photo.url(:logbook))
                end).not_to be_nil
              end
            end
          end

          it "should paginate using the last_record parameter" do
            get :index, params: {format: 'json', last_record: @flights[49].sequence, filter: 'all'}
            expect(response.status).to eql(200)
            expect(JSON.parse(response.body).size).to eql(50)
            JSON.parse(response.body).zip(@flights[50, 50]).each do |(json, flight)|
              expect(json['id']).to eql(flight.sequence)
            end
          end

          it "should not blow up if given an invalid last_record" do
            get :index, params: {format: 'json', last_record: 'wellp', filter: 'all'}
            expect(response.status).to eql(200)
            expect(JSON.parse(response.body).size).to eql(50)
            JSON.parse(response.body).zip(@flights[0, 50]).each do |(json, flight)|
              expect(json['id']).to eql(flight.sequence)
            end
          end
        end

        context "[filter = blog]" do
          it "should return the first 50 flights by date" do
            get :index, params: {format: 'json', filter: 'blog'}
            expect(response.status).to eql(200)
            expect(JSON.parse(response.body).size).to eql(50)
            JSON.parse(response.body).zip(@blog_flights[0, 50]).each do |(json, flight)|
              [ :remarks, :duration ].each do |attr|
                expect(json[attr.to_s]).to eql(flight.send(attr))
              end
              expect(json['id']).to eql(flight.sequence)
              [ :type, :ident ].each do |attr|
                expect(json['aircraft'][attr.to_s]).to eql(flight.aircraft.send(attr))
              end
              expect(json['url']).to match(/\/flights\/#{flight.to_param}$/)
              expect(json['date']).to eql(I18n.l(flight.date, format: :logbook))
              expect(json['photos'].size).to be <= 4
              json['photos'].each do |attrs|
                expect(flight.photographs.detect do |photo|
                  attrs['thumbnail'] == photo.image.url(:logbook) &&
                    attrs['full'] == photo.image.url &&
                    attrs['caption'] == photo.caption
                end).not_to be_nil
              end
              expect(json['occupants'].size).to eql(flight.occupants.count)
              json['occupants'].each do |attrs|
                expect(flight.occupants.map(&:person).detect do |person|
                  attrs['name'] == person.name &&
                    attrs['url'] =~ /\/people\/#{Regexp.escape person.slug}$/ &&
                    attrs['photo'].include?(person.photo.url(:logbook))
                end).not_to be_nil
              end
            end
          end

          it "should paginate using the last_record parameter" do
            get :index, params: {format: 'json', last_record: @blog_flights[39].sequence, filter: 'blog'}
            expect(response.status).to eql(200)
            expect(JSON.parse(response.body).size).to eql(20)
            JSON.parse(response.body).zip(@blog_flights[40, 20]).each do |(json, flight)|
              expect(json['id']).to eql(flight.sequence)
            end
          end

          it "should not blow up when given an invalid last_record parameter" do
            get :index, params: {format: 'json', last_record: 'yep', filter: 'blog'}
            expect(response.status).to eql(200)
            expect(JSON.parse(response.body).size).to eql(50)
            JSON.parse(response.body).zip(@blog_flights[0, 50]).each do |(json, flight)|
              expect(json['id']).to eql(flight.sequence)
            end
          end
        end
      end

      describe "[people nested resource]" do
        before :all do
          @person = FactoryGirl.create(:person, user: @user)
          flights = 60.times.map do
            flight = FactoryGirl.create(:flight, user: @user, date: Date.today - rand(400))
            FactoryGirl.create :passenger, flight: flight, person: @person
            flight
          end
          @user.update_flight_sequence!
          @flights = Flight.where(id: flights.map(&:id)).order('sequence DESC')
        end

        it "should return the first 50 flights by date where that person was an occupant" do
          get :index, params: {format: 'json', person_id: @person.slug}
          expect(response.status).to eql(200)
          expect(JSON.parse(response.body).size).to eql(50)
          JSON.parse(response.body).zip(@flights[0, 50]).each do |(json, flight)|
            expect(json['id']).to eql(flight.sequence)
          end
        end

        it "should paginate using the last_record parameter" do
          get :index, params: {format: 'json', last_record: @flights[39].sequence, person_id: @person.slug}
          expect(response.status).to eql(200)
          expect(JSON.parse(response.body).size).to eql(20)
          JSON.parse(response.body).zip(@flights[40, 20]).each do |(json, flight)|
            expect(json['id']).to eql(flight.sequence)
          end
        end

        it "should not blow up when given an invalid last_record parameter" do
          get :index, params: {format: 'json', last_record: 'hello', person_id: @person.slug}
          expect(response.status).to eql(200)
          expect(JSON.parse(response.body).size).to eql(50)
          JSON.parse(response.body).zip(@flights[0, 50]).each do |(json, flight)|
            expect(json['id']).to eql(flight.sequence)
          end
        end
      end

      describe "[airports nested resource]" do
        before :all do
          @destination = FactoryGirl.create(:destination, user: @user)
          @flights = 60.times.map { FactoryGirl.create :flight, destination: @destination, user: @user, date: Date.today - rand(400) }
          # red herrings
          FactoryGirl.create :flight, origin: @destination, user: @user
          FactoryGirl.create :stop, destination: @destination, sequence: 1

          @user.update_flight_sequence!
          @flights = Flight.where(id: @flights.map(&:id)).order('sequence DESC')
        end

        it "should return the first 50 flights by date to that airport" do
          get :index, params: {format: 'json', airport_id: @destination.airport.identifier}
          expect(response.status).to eql(200)
          expect(JSON.parse(response.body).size).to eql(50)
          JSON.parse(response.body).zip(@flights[0, 50]).each do |(json, flight)|
            expect(json['id']).to eql(flight.sequence)
          end
        end

        it "should paginate using the last_record parameter" do
          get :index, params: {format: 'json', last_record: @flights[39].sequence, airport_id: @destination.airport.identifier}
          expect(response.status).to eql(200)
          expect(JSON.parse(response.body).size).to eql(20)
          JSON.parse(response.body).zip(@flights[40, 20]).each do |(json, flight)|
            expect(json['id']).to eql(flight.sequence)
          end
        end

        it "should not blow up when given an invalid last_record parameter" do
          get :index, params: {format: 'json', last_record: 'byee!', airport_id: @destination.airport.identifier}
          expect(response.status).to eql(200)
          expect(JSON.parse(response.body).size).to eql(50)
          JSON.parse(response.body).zip(@flights[0, 50]).each do |(json, flight)|
            expect(json['id']).to eql(flight.sequence)
          end
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
      get :show, params: {id: FactoryGirl.create(:flight).to_param}
      expect(response.status).to eql(404)
    end

    context "[valid flight]" do
      before :each do
        @flight = FactoryGirl.create(:flight, user: @user)
      end

      it "should set @flight to the flight" do
        get :show, params: {id: @flight.to_param}
        expect(assigns(:flight)).to eql(@flight)
      end

      it "should render the show template" do
        get :show, params: {id: @flight.to_param}
        expect(response.status).to eql(200)
        expect(response).to render_template('show')
      end
    end
  end

  describe "#edit" do
    before :each do
      session[:user_id] = @user
      request.host = "#{@user.subdomain}.test.host"
    end

    it "should 404 if an invalid flight ID is provided" do
      get :edit, params: {id: 'not-found'}
      expect(response.status).to eql(404)
    end

    it "should 404 if the flight does not belong to the subdomain owner" do
      get :edit, params: {id: FactoryGirl.create(:flight).to_param}
      expect(response.status).to eql(404)
    end

    context "[valid flight]" do
      before :each do
        @flight = FactoryGirl.create(:flight, user: @user)
      end

      it "should set @flight to the flight" do
        get :edit, params: {id: @flight.to_param}
        expect(assigns(:flight)).to eql(@flight)
      end

      it "should add an unsaved photograph to the flight" do
        get :edit, params: {id: @flight.to_param}
        expect(assigns(:flight).photographs.last).to be_new_record
      end

      it "should render the edit template" do
        get :edit, params: {id: @flight.to_param}
        expect(response.status).to eql(200)
        expect(response).to render_template('edit')
      end
    end
  end

  describe "#update" do
    before :each do
      session[:user_id] = @user
      request.host = "#{@user.subdomain}.test.host"
    end

    it "should 404 if an invalid flight ID is provided" do
      patch :update, params: {id: 'not-found'}
      expect(response.status).to eql(404)
    end

    it "should 404 if the flight does not belong to the subdomain owner" do
      patch :update, params: {id: FactoryGirl.create(:flight).to_param}
      expect(response.status).to eql(404)
    end

    context "[valid flight]" do
      before :each do
        @flight = FactoryGirl.create(:flight, user: @user)
      end

      context "[valid attributes]" do
        it "should update the flight from the parameter hash" do
          patch :update, params: {id: @flight.to_param, flight: { blog: "new blog entry" }}
          expect(@flight.reload.blog).to eql("new blog entry")
        end

        it "should redirect to the flight URL" do
          patch :update, params: {id: @flight.to_param, flight: { blog: "new blog entry" }}
          expect(response).to redirect_to(flight_url(@flight))
        end

        it "should update photographs as well" do
          photo = FactoryGirl.create(:photograph, flight: @flight, caption: 'foo')
          patch :update, params: {id: @flight.to_param, flight: { blog: 'new 2', photographs_attributes: { '0' => { caption: 'bar', _destroy: '0', id: photo.id.to_s } } }}
          expect(photo.reload.caption).to eql('bar')
        end
      end

      context "[invalid attributes]" do
        it "should leave the flight unchanged" do
          skip "No invalid attributes"
          attrs = @flight.attributes
          patch :update, params: {id: @flight.to_param, flight: { blog: 'halp?' }}
          expect(@flight.reload.attributes).to eql(attrs)
        end

        it "should render the edit template" do
          skip "No invalid attributes"
          patch :update, params: {id: @flight.to_param, flight: { blog: 'halp?' }}
          expect(response).to render_template('edit')
        end
      end
    end
  end
end
