require 'spec_helper'
require 'sidekiq/testing'
require 'importer'

describe ImportsController, type: :controller do
  before(:each) { Importer.jobs.clear }

  describe "#new" do
    it "should redirect if no user is logged in" do
      get :new
      expect(response).to be_redirect
    end

    it "should redirect if the user is not the subdomain owner" do
      session[:user_id] = FactoryGirl.create(:user).id
      request.host = "#{FactoryGirl.create(:user).subdomain}.test.host"
      get :new
      expect(response).to be_redirect
    end

    context "[subdomain owner]" do
      before :each do
        @user = FactoryGirl.create(:user)
        session[:user_id] = @user.id
        request.host = "#{@user.subdomain}.test.host"
        get :new
      end

      it "should render the form" do
        expect(response).to render_template('new')
      end

      it "should set @import to an unsaved new Import" do
        expect(assigns(:import)).to be_kind_of(Import)
        expect(assigns(:import)).to be_new_record
        expect(assigns(:import).user).to eql(@user)
      end
    end
  end

  describe "#create" do
    it "should redirect if no user is logged in" do
      post :create, import: {}
      expect(response).to be_redirect
    end

    it "should redirect if the user is not the subdomain owner" do
      session[:user_id] = FactoryGirl.create(:user).id
      request.host = "#{FactoryGirl.create(:user).subdomain}.test.host"
      post :create, import: {}
      expect(response).to be_redirect
    end

    context "[subdomain owner]" do
      before :each do
        @user = FactoryGirl.create(:user)
        session[:user_id] = @user.id
        request.host = "#{@user.subdomain}.test.host"
      end

      context "[valid values]" do
        before :each do
          @attributes = FactoryGirl.attributes_for(:import, user: @user, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'logten.zip'), 'application/zip'))
        end

        it "should create a new Import" do
          post :create, import: @attributes
          expect(@user.imports.count).to eql(1)
          import = @user.imports.first
          expect(import.logbook.original_filename).to eql('logten.zip')
        end

        it "should enqueue the Import" do
          post :create, import: @attributes
          expect(Importer.jobs.size).to eql(1)
        end

        it "should redirect to the import progress page" do
          post :create, import: @attributes
          expect(response).to redirect_to(@user.imports.first)
        end
      end

      context "[invalid values]" do
        before :each do
          @attributes = FactoryGirl.attributes_for(:import, user: @user, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'bogus.txt'), 'text/plain'))
        end

        it "should move errors on the Paperclip aux fields to the main Paperclip field" do
          post :create, import: @attributes
          import = assigns(:import)
          expect(import.errors[:logbook]).not_to be_empty
          expect(import.errors[:logbook]).to eql(import.errors[:logbook_content_type])
        end

        it "should render the form" do
          post :create, import: @attributes
          expect(response).to render_template('new')
        end

        it "should set @import to the unsaved Import" do
          post :create, import: @attributes
          expect(assigns(:import)).to be_kind_of(Import)
          expect(assigns(:import)).to be_new_record
        end

        it "should not enqueue anything" do
          post :create, import: @attributes
          expect(Importer.jobs).to be_empty
        end
      end
    end
  end

  describe "#show" do
    it "should redirect if no user is logged in" do
      get :show, id: FactoryGirl.create(:import).id
      expect(response).to be_redirect
    end

    it "should redirect if the user is not the subdomain owner" do
      user = FactoryGirl.create(:user)
      session[:user_id] = user.id
      request.host = "#{FactoryGirl.create(:user).subdomain}.test.host"
      get :show, id: FactoryGirl.create(:import, user: user).id
      expect(response).to be_redirect
    end

    context "[subdomain owner]" do
      before :each do
        @user = FactoryGirl.create(:user)
        session[:user_id] = @user.id
        request.host = "#{@user.subdomain}.test.host"
      end
      
      it "should 404 if the Import does not belong to the current user" do
        get :show, id: FactoryGirl.create(:import).id
        expect(response.status).to eql(404)
      end

      it "should 404 if the Import is not found" do
        get :show, id: 'not-found'
        expect(response.status).to eql(404)
      end

      it "should set @import to the Import" do
        import = FactoryGirl.create(:import, user: @user)
        get :show, id: import.id
        expect(assigns(:import)).to eql(import)
      end
    end
  end
end
