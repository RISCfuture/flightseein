require 'spec_helper'

describe PeopleController do
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
      before :all do
        @people = (1..60).map { Factory :person, user: @user }
        @people.each { |pers| Factory :flight, user: @user, pic: pers }
        @people.each(&:update_hours!)
        @people = @people.sort_by { |pers| [ pers.hours, pers.id ] }.reverse
      end

      it "should return the first 50 people by hours" do
        get :index, format: 'json'
        response.status.should eql(200)
          JSON.parse(response.body).size.should eql(50)
          JSON.parse(response.body).zip(@people[0, 50]).each do |(json, person)|
            json['id'].should eql(person.id)
            json['name'].should eql(person.name)
            json['hours'].should be_within(0.05).of(person.hours)
            json['url'].should =~ /\/people\/#{person.slug}$/
            json['flights'].should eql(person.flights.count)
            json['photo'].should eql(person.photo.url(:carousel))
          end
      end

      it "should paginate using the last_record parameter" do
        get :index, format: 'json', last_record: @people[49].id
        response.status.should eql(200)
        JSON.parse(response.body).size.should eql(10)
        JSON.parse(response.body).zip(@people[50, 10]).each do |(json, person)|
          json['id'].should eql(person.id)
        end
      end

      it "should not blow up if given an invalid last_record" do
        get :index, format: 'json', last_record: Factory(:person).id
        response.status.should eql(200)
        JSON.parse(response.body).size.should eql(50)
        JSON.parse(response.body).zip(@people[0, 50]).each do |(json, person)|
          json['id'].should eql(person.id)
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
      get :show, id: Factory(:person).slug
      response.status.should eql(404)
    end

    context "[valid person]" do
      before :each do
        @person = Factory(:person, user: @user)
      end

      it "should set @notes to a Redcarpet with the person's notes" do
        @person.update_attribute :notes, 'notes here'
        get :show, id: @person.slug
        assigns(:notes).should be_kind_of(Redcarpet)
        assigns(:notes).text.should eql('notes here')
      end

      it "should set @notes to nil if the person has no notes" do
        @person.update_attribute :notes, ''
        get :show, id: @person.slug
        assigns(:notes).should be_nil

        @person.update_attribute :notes, nil
        get :show, id: @person.slug
        assigns(:notes).should be_nil
      end

      it "should set @person to the person" do
        get :show, id: @person.slug
        assigns(:person).should eql(@person)
      end

      it "should render the show template" do
        get :show, id: @person.slug
        response.status.should eql(200)
        response.should render_template('show')
      end
    end
  end
end
