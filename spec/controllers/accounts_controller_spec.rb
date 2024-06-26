require 'rails_helper'

describe AccountsController, type: :controller do
  describe "#show" do
    before :each do
      @user = FactoryBot.create(:user)
      request.host = "#{@user.subdomain}.test.host"
    end

    it "should render the account page for the subdomain owner" do
      get :show
      expect(response).to render_template('show')
    end

    it "should set @flight_count to the number of flights" do
      FactoryBot.create_list :flight, 7, user: @user
      get :show
      expect(assigns(:flight_count)).to eql(7)
    end

    it "should set @pax_count to the number of people" do
      FactoryBot.create_list :person, 8, user: @user, hours: 2.0
      # red herrings
      FactoryBot.create :person, user: @user, hours: 0.0
      FactoryBot.create :person, user: @user, hours: 2.0, me: true

      get :show

      expect(assigns(:pax_count)).to eql(8)
    end

    it "should set @airport_count to the number of airports" do
      FactoryBot.create_list :flight, 9, user: @user
      FactoryBot.create(:flight, user: @user, destination: @user.destinations.first)

      get :show

      expect(assigns(:airport_count)).to eql(19) # 9 flights * 2 destinations + flight w/1 unique destination
    end

    it "should set @flight_images to the last four flights" do
      flights = Array.new(5) { FactoryBot.create :flight, user: @user, date: Date.today - rand(100) }.reverse.sort_by { |f| [ f.date, f.id ] }.reverse
      # reverse twice so we get a sort by date then ID
      @user.update_flight_sequence!
      get :show
      expect(assigns(:flight_images).map(&:id)).to eql(flights[0,4].map(&:id))
    end

    it "should set @flight_images to the last flights if there are fewer than four" do
      flights = Array.new(2) { FactoryBot.create :flight, user: @user, date: Date.today - rand(100) }.reverse.sort_by { |f| [ f.date, f.id ] }.reverse
      # reverse twice so we get a sort by date then ID
      @user.update_flight_sequence!
      get :show
      expect(assigns(:flight_images).map(&:id)).to eql(flights.map(&:id))
    end

    it "should set @pax_images to four random people with photos" do
      people = FactoryBot.create_list(:person, 4, hours: 4.0, user: @user, photo: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'image.jpg'), 'image/jpeg'))
      # red herrings
      FactoryBot.create :person, user: @user, hours: 2.0
      FactoryBot.create :person, user: @user, hours: 0.0
      FactoryBot.create :person, user: @user, me: true

      get :show

      expect(assigns(:pax_images).size).to eql(4)
      people.each { |person| expect(assigns(:pax_images).map(&:id)).to include(person.id) }
    end

    it "should fill @pax_images if four people with photos aren't available" do
      people = FactoryBot.create_list(:person, 2, hours: 2.0, user: @user, photo: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'image.jpg'), 'image/jpeg'))
      people << FactoryBot.create(:person, user: @user, hours: 2.0)
      people << FactoryBot.create(:person, user: @user, hours: 2.0)
      # red herrings
      FactoryBot.create :person, user: @user, hours: 0.0
      FactoryBot.create :person, user: @user, hours: 2.0, me: true

      get :show

      expect(assigns(:pax_images).size).to eql(4)
      people.each { |person| expect(assigns(:pax_images).map(&:id)).to include(person.id) }
    end

    it "should use as many people as are available if there are fewer than four" do
      people = FactoryBot.create_list(:person, 2, hours: 2.0, user: @user, photo: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'image.jpg'), 'image/jpeg'))
      # red herrings
      FactoryBot.create :person, user: @user, hours: 0.0
      FactoryBot.create :person, user: @user, hours: 2.0, me: true

      get :show

      expect(assigns(:pax_images).size).to eql(2)
      people.each { |person| expect(assigns(:pax_images).map(&:id)).to include(person.id) }
    end

    it "should set @airport_images to four random destinations with photos" do
      dests = FactoryBot.create_list(:destination, 4, user: @user, photo: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'image.jpg'), 'image/jpeg'))
      FactoryBot.create :destination, user: @user

      get :show

      expect(assigns(:airport_images).size).to eql(4)
      dests.each { |dest| expect(assigns(:airport_images).map(&:airport_id)).to include(dest.airport_id) }
    end

    it "should fill @airport_images if four destinations with photos aren't available" do
      dests = FactoryBot.create_list(:destination, 2, user: @user, photo: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'image.jpg'), 'image/jpeg'))
      dests << FactoryBot.create(:destination, user: @user)
      dests << FactoryBot.create(:destination, user: @user)

      get :show

      expect(assigns(:airport_images).size).to eql(4)
      dests.each { |dest| expect(assigns(:airport_images).map(&:airport_id)).to include(dest.airport_id) }
    end

    it "should use as many destinations as are available if there are fewer than four" do
      dests = FactoryBot.create_list(:destination, 2, user: @user, photo: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'image.jpg'), 'image/jpeg'))

      get :show

      expect(assigns(:airport_images).size).to eql(2)
      dests.each { |dest| expect(assigns(:airport_images).map(&:airport_id)).to include(dest.airport_id) }
    end
  end

  describe "#edit" do
    it "should render the edit page for the subdomain owner" do
      user = FactoryBot.create(:user)
      request.host = "#{user.subdomain}.test.host"

      get :edit, session: {user_id: user.id}

      expect(response).to render_template('edit')
    end

    it "should redirect if logged out" do
      request.host = "#{FactoryBot.create(:user).subdomain}.test.host"
      get :edit
      expect(response).to be_redirect
    end

    it "should redirect if the current user is not the account owner" do
      session[:user_id] = FactoryBot.create(:user).id
      request.host = "#{FactoryBot.create(:user).subdomain}.test.host"
      get :edit
      expect(response).to be_redirect
    end
  end

  describe "#update" do
    it "should redirect if logged out" do
      request.host = "#{FactoryBot.create(:user).subdomain}.test.host"
      patch :update, params: {user: FactoryBot.attributes_for(:user)}
      expect(response).to be_redirect
    end

    it "should redirect if the current user is not the account owner" do
      request.host = "#{FactoryBot.create(:user).subdomain}.test.host"
      patch :update, params: {user: FactoryBot.attributes_for(:user)}, session: {user_id: FactoryBot.create(:user).id}
      expect(response).to be_redirect
    end

    context "[subdomain owner]" do
      before :each do
        @user = FactoryBot.create(:user)
        session[:user_id] = @user.id
        request.host = "#{@user.subdomain}.test.host"
      end

      context "[valid values]" do
        before :each do
          @attributes = FactoryBot.attributes_for(:user).slice(:password, :name, :quote, :subdomain, :avatar)
          patch :update, params: {user: @attributes}
        end

        it "should update the user" do
          @user.reload
          @attributes.each { |k,v| expect(@user.send(k)).to eql(v) }
        end

        it "should redirect to the account page" do
          expect(response).to redirect_to(root_url(subdomain: @user.reload.subdomain))
        end
      end

      context "[invalid values]" do
        before :each do
          @attributes = { subdomain: 'invalid/subdomain' }
          patch :update, params: {user: @attributes}
        end

        it "should leave the user untouched" do
          expect { @user.reload }.not_to change(@user, :updated_at)
        end

        it "should render the form" do
          expect(response).to render_template('edit')
        end
      end
    end
  end

  describe "#destroy" do
    it "should redirect if logged out" do
      request.host = "#{FactoryBot.create(:user).subdomain}.test.host"
      delete :destroy
      expect(response).to be_redirect
    end

    it "should redirect if the current user is not the account owner" do
      request.host = "#{FactoryBot.create(:user).subdomain}.test.host"
      delete :destroy, session: {user_id: FactoryBot.create(:user).id}
      expect(response).to be_redirect
    end

    context "[subdomain owner]" do
      before :each do
        @user = FactoryBot.create(:user)
        session[:user_id] = @user.id
        request.host = "#{@user.subdomain}.test.host"
        delete :destroy
      end

      it "should deactivate the user" do
        expect(@user.reload).not_to be_active
      end

      it "should log the user out" do
        expect(session[:user_id]).to be_nil
      end

      it "should redirect to the logged-out home page" do
        expect(response).to redirect_to(root_url)
      end
    end
  end
end
