require 'spec_helper'

describe AccountsController do
  describe "#show" do
    before :each do
      @user = Factory(:user)
      request.host = "#{@user.subdomain}.test.host"
    end

    it "should render the account page for the subdomain owner" do
      get :show
      response.should render_template('show')
    end

    it "should set @flight_count to the number of flights" do
      7.times { Factory :flight, user: @user }
      get :show
      assigns(:flight_count).should eql(7)
    end

    it "should set @pax_count to the number of people" do
      8.times { Factory :person, user: @user }
      get :show
      assigns(:pax_count).should eql(8)
    end

    it "should set @airport_count to the number of airports" do
      9.times { Factory :flight, user: @user }
      Factory(:flight, user: @user, destination: @user.destinations.first)

      get :show
      
      assigns(:airport_count).should eql(19) # 9 flights * 2 destinations + flight w/1 unique destination
    end

    it "should set @flight_images to the last four flights" do
      flights = (1..5).map { Factory :flight, user: @user, date: Date.today - rand(100) }.reverse.sort_by { |f| [ f.date, f.id ] }.reverse
      # reverse twice so we get a sort by date then ID
      get :show
      assigns(:flight_images).map(&:id).should eql(flights[0,4].map(&:id))
    end

    it "should set @flight_images to the last flights if there are fewer than four" do
      flights = (1..2).map { Factory :flight, user: @user, date: Date.today - rand(100) }.reverse.sort_by { |f| [ f.date, f.id ] }.reverse
      # reverse twice so we get a sort by date then ID
      get :show
      assigns(:flight_images).map(&:id).should eql(flights.map(&:id))
    end

    it "should set @pax_images to four random people with photos" do
      people = (1..4).map { Factory :person, user: @user, photo: open(Rails.root.join('spec', 'fixtures', 'image.jpg')) }
      Factory :person, user: @user
      get :show
      assigns(:pax_images).size.should eql(4)
      people.each { |person| assigns(:pax_images).map(&:id).should include(person.id) }
    end

    it "should fill @pax_images if four people with photos aren't available" do
      people = (1..2).map { Factory :person, user: @user, photo: open(Rails.root.join('spec', 'fixtures', 'image.jpg')) }
      people << Factory(:person, user: @user)
      people << Factory(:person, user: @user)
      get :show
      assigns(:pax_images).size.should eql(4)
      people.each { |person| assigns(:pax_images).map(&:id).should include(person.id) }
    end

    it "should use as many people as are available if there are fewer than four" do
      people = (1..2).map { Factory :person, user: @user, photo: open(Rails.root.join('spec', 'fixtures', 'image.jpg')) }
      get :show
      assigns(:pax_images).size.should eql(2)
      people.each { |person| assigns(:pax_images).map(&:id).should include(person.id) }
    end

    it "should set @airport_images to four random destinations with photos" do
      dests = (1..4).map { Factory :destination, user: @user, photo: open(Rails.root.join('spec', 'fixtures', 'image.jpg')) }
      Factory :destination, user: @user
      get :show
      assigns(:airport_images).size.should eql(4)
      dests.each { |dest| assigns(:airport_images).map(&:airport_id).should include(dest.airport_id) }
    end

    it "should fill @airport_images if four destinations with photos aren't available" do
      dests = (1..2).map { Factory :destination, user: @user, photo: open(Rails.root.join('spec', 'fixtures', 'image.jpg')) }
      dests << Factory(:destination, user: @user)
      dests << Factory(:destination, user: @user)
      get :show
      assigns(:airport_images).size.should eql(4)
      dests.each { |dest| assigns(:airport_images).map(&:airport_id).should include(dest.airport_id) }
    end

    it "should use as many destinations as are available if there are fewer than four" do
      dests = (1..2).map { Factory :destination, user: @user, photo: open(Rails.root.join('spec', 'fixtures', 'image.jpg')) }
      get :show
      assigns(:airport_images).size.should eql(2)
      dests.each { |dest| assigns(:airport_images).map(&:airport_id).should include(dest.airport_id) }
    end

    it "should set @quote to a RedCarpet for the quote" do
      @user.update_attribute :quote, 'my quote'
      get :show
      assigns(:quote).should be_kind_of(Redcarpet)
      assigns(:quote).text.should eql('my quote')
    end

    it "should set @quote to nil if the user has no quote" do
      @user.update_attribute :quote, ''
      get :show
      assigns(:quote).should be_nil

      @user.update_attribute :quote, nil
      get :show
      assigns(:quote).should be_nil
    end
  end

  describe "#edit" do
    it "should render the edit page for the subdomain owner" do
      user = Factory(:user)
      request.host = "#{user.subdomain}.test.host"
      session[:user_id] = user.id

      get :edit

      response.should render_template('edit')
    end

    it "should redirect if logged out" do
      request.host = "#{Factory(:user).subdomain}.test.host"
      get :edit
      response.should be_redirect
    end

    it "should redirect if the current user is not the account owner" do
      session[:user_id] = Factory(:user).id
      request.host = "#{Factory(:user).subdomain}.test.host"
      get :edit
      response.should be_redirect
    end
  end

  describe "#update" do
    it "should redirect if logged out" do
      request.host = "#{Factory(:user).subdomain}.test.host"
      put :update, user: Factory.attributes_for(:user)
      response.should be_redirect
    end

    it "should redirect if the current user is not the account owner" do
      session[:user_id] = Factory(:user).id
      request.host = "#{Factory(:user).subdomain}.test.host"
      put :update, user: Factory.attributes_for(:user)
      response.should be_redirect
    end

    context "[subdomain owner]" do
      before :each do
        @user = Factory(:user)
        session[:user_id] = @user.id
        request.host = "#{@user.subdomain}.test.host"
      end

      context "[valid values]" do
        before :each do
          @attributes = Factory.attributes_for(:user).slice(*User._accessible_attributes.to_a)
          put :update, user: @attributes
        end

        it "should update the user" do
          @user.reload
          @attributes.each { |k,v| @user.send(k).should eql(v) }
        end

        it "should redirect to the account page" do
          response.should redirect_to(root_url(subdomain: @user.subdomain))
        end
      end

      context "[invalid values]" do
        before :each do
          @attributes = { subdomain: 'invalid/subdomain' }
          put :update, user: @attributes
        end

        it "should leave the user untouched" do
          -> { @user.reload }.should_not change(@user, :attributes)
        end

        it "should render the form" do
          response.should render_template('edit')
        end
      end
    end
  end

  describe "#destroy" do
    it "should redirect if logged out" do
      request.host = "#{Factory(:user).subdomain}.test.host"
      delete :destroy
      response.should be_redirect
    end

    it "should redirect if the current user is not the account owner" do
      session[:user_id] = Factory(:user).id
      request.host = "#{Factory(:user).subdomain}.test.host"
      delete :destroy
      response.should be_redirect
    end

    context "[subdomain owner]" do
      before :each do
        @user = Factory(:user)
        session[:user_id] = @user.id
        request.host = "#{@user.subdomain}.test.host"
        delete :destroy
      end

      it "should deactivate the user" do
        @user.reload.should_not be_active
      end

      it "should log the user out" do
        session[:user_id].should be_nil
      end

      it "should redirect to the logged-out home page" do
        response.should redirect_to(root_url)
      end
    end
  end
end
