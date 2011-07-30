require 'spec_helper'

describe FlightsController do
  before :all do
    @user = Factory(:user)
  end

  before :each do
    request.host = "#{@user.subdomain}.test.host"
  end

  describe "#index" do
    describe ".html" do
      it "should render the index template" do
        get :index
        response.status.should eql(200)
        response.should render_template('index')
      end
    end

    describe ".json" do
      describe "[basic route]" do
        before :all do
          @blog_flights = (1..60).map { Factory :flight, user: @user, blog: "Hello, world!", date: Date.today - rand(600) }
          noblog_flights = (1..60).map { Factory :flight, user: @user, blog: nil, date: Date.today - rand(600) }
          @user.update_flight_sequence!
          @blog_flights = Flight.where(id: @blog_flights.map(&:id)).order('sequence DESC').all
          @flights = Flight.where(id: (@blog_flights + noblog_flights).map(&:id)).order('sequence DESC').all

          100.times { Factory :photograph, flight: @flights.sample }
          50.times { @flights.sample.passengers << Factory(:person, user: @user) }
        end

        it "should use filter=all by default" do
          get :index, format: 'json'
          response.status.should eql(200)
          JSON.parse(response.body).map { |hsh| hsh['id'] }.should eql(@flights[0, 50].map(&:sequence))
        end

        context "[filter = all]" do
          it "should return the first 50 flights by date" do
            get :index, format: 'json', filter: 'all'
            response.status.should eql(200)
            JSON.parse(response.body).size.should eql(50)
            JSON.parse(response.body).zip(@flights[0, 50]).each do |(json, flight)|
              [ :remarks, :duration ].each do |attr|
                json[attr.to_s].should eql(flight.send(attr))
              end
              json['id'].should eql(flight.sequence)
              [ :type, :ident ].each do |attr|
                json['aircraft'][attr.to_s].should eql(flight.aircraft.send(attr))
              end
              json['url'].should =~ /\/flights\/#{flight.id}$/
              json['date'].should eql(I18n.l(flight.date, format: :logbook))
              json['photos'].size.should <= 4
              json['photos'].each { |url| flight.photographs.map { |photo| photo.image.url :logbook }.should include(url) }
              json['people'].size.should eql(flight.people.count)
              json['people'].each do |attrs|
                flight.people.detect do |person|
                  attrs['name'].should eql(person.name)
                  attrs['url'].should =~ /\/people\/#{Regexp.escape person.slug}$/
                  attrs['photo'].should eql(person.photo.url(:logbook))
                end.should_not be_nil
              end
            end
          end

          it "should paginate using the last_record parameter" do
            get :index, format: 'json', last_record: @flights[49].sequence, filter: 'all'
            response.status.should eql(200)
            JSON.parse(response.body).size.should eql(50)
            JSON.parse(response.body).zip(@flights[50, 50]).each do |(json, flight)|
              json['id'].should eql(flight.sequence)
            end
          end

          it "should not blow up if given an invalid last_record" do
            get :index, format: 'json', last_record: 'wellp', filter: 'all'
            response.status.should eql(200)
            JSON.parse(response.body).size.should eql(50)
            JSON.parse(response.body).zip(@flights[0, 50]).each do |(json, flight)|
              json['id'].should eql(flight.sequence)
            end
          end
        end

        context "[filter = blog]" do
          it "should return the first 50 flights by date" do
            get :index, format: 'json', filter: 'blog'
            response.status.should eql(200)
            JSON.parse(response.body).size.should eql(50)
            JSON.parse(response.body).zip(@blog_flights[0, 50]).each do |(json, flight)|
              [ :remarks, :duration ].each do |attr|
                json[attr.to_s].should eql(flight.send(attr))
              end
              json['id'].should eql(flight.sequence)
              [ :type, :ident ].each do |attr|
                json['aircraft'][attr.to_s].should eql(flight.aircraft.send(attr))
              end
              json['url'].should =~ /\/flights\/#{flight.id}$/
              json['date'].should eql(I18n.l(flight.date, format: :logbook))
              json['photos'].size.should <= 4
              json['photos'].each { |url| flight.photographs.map { |photo| photo.image.url :logbook }.should include(url) }
              json['people'].size.should eql(flight.people.count)
              json['people'].each do |attrs|
                flight.people.detect do |person|
                  attrs['name'].should eql(person.name)
                  attrs['url'].should =~ /\/people\/#{Regexp.escape person.slug}$/
                  attrs['photo'].should eql(person.photo.url(:logbook))
                end.should_not be_nil
              end
            end
          end

          it "should paginate using the last_record parameter" do
            get :index, format: 'json', last_record: @blog_flights[39].sequence, filter: 'blog'
            response.status.should eql(200)
            JSON.parse(response.body).size.should eql(20)
            JSON.parse(response.body).zip(@blog_flights[40, 20]).each do |(json, flight)|
              json['id'].should eql(flight.sequence)
            end
          end

          it "should not blow up when given an invalid last_record parameter" do
            get :index, format: 'json', last_record: 'yep', filter: 'blog'
            response.status.should eql(200)
            JSON.parse(response.body).size.should eql(50)
            JSON.parse(response.body).zip(@blog_flights[0, 50]).each do |(json, flight)|
              json['id'].should eql(flight.sequence)
            end
          end
        end
      end

      describe "[people nested resource]" do
        before :all do
          @person = Factory(:person, user: @user)
          pic_flights = (1..20).map { Factory :flight, user: @user, pic: @person, date: Date.today - rand(400) }
          sic_flights = (1..20).map { Factory :flight, user: @user, sic: @person, date: Date.today - rand(400) }
          pax_flights = (1..20).map do
            flight = Factory(:flight, user: @user, date: Date.today - rand(400))
            flight.passengers << @person
            flight.update_people!
            flight
          end
          @user.update_flight_sequence!
          @flights = Flight.where(id: (pic_flights + sic_flights + pax_flights).map(&:id)).order('sequence DESC').all
        end

        it "should return the first 50 flights by date where that person was a pilot, copilot, or passenger" do
          get :index, format: 'json', person_id: @person.slug
          response.status.should eql(200)
          JSON.parse(response.body).size.should eql(50)
          JSON.parse(response.body).zip(@flights[0, 50]).each do |(json, flight)|
            json['id'].should eql(flight.sequence)
          end
        end

        it "should paginate using the last_record parameter" do
          get :index, format: 'json', last_record: @flights[39].sequence, person_id: @person.slug
          response.status.should eql(200)
          JSON.parse(response.body).size.should eql(20)
          JSON.parse(response.body).zip(@flights[40, 20]).each do |(json, flight)|
            json['id'].should eql(flight.sequence)
          end
        end

        it "should not blow up when given an invalid last_record parameter" do
          get :index, format: 'json', last_record: 'hello', person_id: @person.slug
          response.status.should eql(200)
          JSON.parse(response.body).size.should eql(50)
          JSON.parse(response.body).zip(@flights[0, 50]).each do |(json, flight)|
            json['id'].should eql(flight.sequence)
          end
        end
      end

      describe "[airports nested resource]" do
        before :all do
          @destination = Factory(:destination, user: @user)
          @flights = (1..60).map { Factory :flight, destination: @destination, user: @user, date: Date.today - rand(400) }
          # red herrings
          Factory :flight, origin: @destination, user: @user
          Factory :stop, destination: @destination, sequence: 1

          @user.update_flight_sequence!
          @flights = Flight.where(id: @flights.map(&:id)).order('sequence DESC').all
        end

        it "should return the first 50 flights by date to that airport" do
          get :index, format: 'json', airport_id: @destination.airport.identifier
          response.status.should eql(200)
          JSON.parse(response.body).size.should eql(50)
          JSON.parse(response.body).zip(@flights[0, 50]).each do |(json, flight)|
            json['id'].should eql(flight.sequence)
          end
        end

        it "should paginate using the last_record parameter" do
          get :index, format: 'json', last_record: @flights[39].sequence, airport_id: @destination.airport.identifier
          response.status.should eql(200)
          JSON.parse(response.body).size.should eql(20)
          JSON.parse(response.body).zip(@flights[40, 20]).each do |(json, flight)|
            json['id'].should eql(flight.sequence)
          end
        end

        it "should not blow up when given an invalid last_record parameter" do
          get :index, format: 'json', last_record: 'byee!', airport_id: @destination.airport.identifier
          response.status.should eql(200)
          JSON.parse(response.body).size.should eql(50)
          JSON.parse(response.body).zip(@flights[0, 50]).each do |(json, flight)|
            json['id'].should eql(flight.sequence)
          end
        end
      end
    end
  end

  describe "#show" do
    it "should 404 if an invalid flight ID is provided" do
      get :show, id: 'not-found'
      response.status.should eql(404)
    end

    it "should 404 if the flight does not belong to the subdomain owner" do
      get :show, id: Factory(:flight).id
      response.status.should eql(404)
    end

    context "[valid flight]" do
      before :each do
        @flight = Factory(:flight, user: @user)
      end

      it "should set @blog to a RedCarpet instance for the flight blog" do
        @flight.update_attribute :blog, "Hello, world!"

        get :show, id: @flight.id

        assigns(:blog).should be_kind_of(Redcarpet)
        assigns(:blog).text.should eql(@flight.blog)
      end

      it "should set @blog to nil if the flight has no blog" do
        @flight.update_attribute :blog, ""
        get :show, id: @flight.id
        assigns(:blog).should be_nil

        @flight.update_attribute :blog, nil
        get :show, id: @flight.id
        assigns(:blog).should be_nil
      end

      it "should set @flight to the flight" do
        get :show, id: @flight.id
        assigns(:flight).should eql(@flight)
      end

      it "should render the show template" do
        get :show, id: @flight.id
        response.status.should eql(200)
        response.should render_template('show')
      end
    end
  end

  describe "#edit" do
    before :each do
      session[:user_id] = @user
      request.host = "#{@user.subdomain}.test.host"
    end

    it "should 404 if an invalid flight ID is provided" do
      get :edit, id: 'not-found'
      response.status.should eql(404)
    end

    it "should 404 if the flight does not belong to the subdomain owner" do
      get :edit, id: Factory(:flight).id
      response.status.should eql(404)
    end

    context "[valid flight]" do
      before :each do
        @flight = Factory(:flight, user: @user)
      end

      it "should set @flight to the flight" do
        get :edit, id: @flight.id
        assigns(:flight).should eql(@flight)
      end

      it "should add an unsaved photograph to the flight" do
        get :edit, id: @flight.id
        assigns(:flight).photographs.last.should be_new_record
      end

      it "should render the edit template" do
        get :edit, id: @flight.id
        response.status.should eql(200)
        response.should render_template('edit')
      end
    end
  end

  describe "#update" do
    before :each do
      session[:user_id] = @user
      request.host = "#{@user.subdomain}.test.host"
    end
    
    it "should 404 if an invalid flight ID is provided" do
      put :update, id: 'not-found'
      response.status.should eql(404)
    end

    it "should 404 if the flight does not belong to the subdomain owner" do
      put :update, id: Factory(:flight).id
      response.status.should eql(404)
    end

    context "[valid flight]" do
      before :each do
        @flight = Factory(:flight, user: @user)
      end

      context "[valid attributes]" do
        it "should update the flight from the parameter hash" do
          put :update, id: @flight.id, flight: { blog: "new blog entry" }
          @flight.reload.blog.should eql("new blog entry")
        end

        it "should redirect to the flight URL" do
          put :update, id: @flight.id, flight: { blog: "new blog entry" }
          response.should redirect_to(flight_url(@flight))
        end

        it "should update photographs as well" do
          photo = Factory(:photograph, flight: @flight, caption: 'foo')
          put :update, id: @flight.id, flight: { blog: 'new 2', photographs_attributes: { '0' => { caption: 'bar', _destroy: '0', id: photo.id } } }
          photo.reload.caption.should eql('bar')
        end
      end

      context "[invalid attributes]" do
        it "should leave the flight unchanged" do
          attrs = @flight.attributes
          put :update, id: @flight.id, flight: { duration: 'halp?' }
          @flight.reload.attributes.should eql(attrs)
        end

        it "should render the edit template" do
          put :update, id: @flight.id, flight: { duration: 'halp?' }
          response.should render_template('edit')
        end
      end
    end
  end
end
