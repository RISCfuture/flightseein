require 'spec_helper'

describe ImportsController do
  before :each do
    Import.stub(:perform)
  end

  describe "#new" do
    it "should redirect if no user is logged in" do
      get :new
      response.should be_redirect
    end

    it "should redirect if the user is not the subdomain owner" do
      session[:user_id] = FactoryGirl.create(:user).id
      request.host = "#{FactoryGirl.create(:user).subdomain}.test.host"
      get :new
      response.should be_redirect
    end

    context "[subdomain owner]" do
      before :each do
        @user = FactoryGirl.create(:user)
        session[:user_id] = @user.id
        request.host = "#{@user.subdomain}.test.host"
        get :new
      end

      it "should render the form" do
        response.should render_template('new')
      end

      it "should set @import to an unsaved new Import" do
        assigns(:import).should be_kind_of(Import)
        assigns(:import).should be_new_record
        assigns(:import).user.should eql(@user)
      end
    end
  end

  describe "#create" do
    it "should redirect if no user is logged in" do
      post :create, import: {}
      response.should be_redirect
    end

    it "should redirect if the user is not the subdomain owner" do
      session[:user_id] = FactoryGirl.create(:user).id
      request.host = "#{FactoryGirl.create(:user).subdomain}.test.host"
      post :create, import: {}
      response.should be_redirect
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
          @user.imports.count.should eql(1)
          import = @user.imports.first
          import.logbook.original_filename.should eql('logten.zip')
        end

        it "should enqueue the Import" do
          Resque.should_receive(:enqueue).once.with(Import, an_instance_of(Fixnum))
          post :create, import: @attributes
        end

        it "should redirect to the import progress page" do
          post :create, import: @attributes
          response.should redirect_to(@user.imports.first)
        end
      end

      context "[invalid values]" do
        before :each do
          @attributes = FactoryGirl.attributes_for(:import, user: @user, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'bogus.txt'), 'text/plain'))
        end

        it "should move errors on the Paperclip aux fields to the main Paperclip field" do
          post :create, import: @attributes
          import = assigns(:import)
          import.errors[:logbook].should_not be_empty
          import.errors[:logbook].should eql(import.errors[:logbook_content_type])
        end

        it "should render the form" do
          post :create, import: @attributes
          response.should render_template('new')
        end

        it "should set @import to the unsaved Import" do
          post :create, import: @attributes
          assigns(:import).should be_kind_of(Import)
          assigns(:import).should be_new_record
        end

        it "should not enqueue anything" do
          Resque.should_not_receive(:enqueue)
          post :create, import: @attributes
        end
      end
    end
  end

  describe "#show" do
    it "should redirect if no user is logged in" do
      get :show, id: FactoryGirl.create(:import).id
      response.should be_redirect
    end

    it "should redirect if the user is not the subdomain owner" do
      user = FactoryGirl.create(:user)
      session[:user_id] = user.id
      request.host = "#{FactoryGirl.create(:user).subdomain}.test.host"
      get :show, id: FactoryGirl.create(:import, user: user).id
      response.should be_redirect
    end

    context "[subdomain owner]" do
      before :each do
        @user = FactoryGirl.create(:user)
        session[:user_id] = @user.id
        request.host = "#{@user.subdomain}.test.host"
      end
      
      it "should 404 if the Import does not belong to the current user" do
        get :show, id: FactoryGirl.create(:import).id
        response.status.should eql(404)
      end

      it "should 404 if the Import is not found" do
        get :show, id: 'not-found'
        response.status.should eql(404)
      end

      it "should set @import to the Import" do
        import = FactoryGirl.create(:import, user: @user)
        get :show, id: import.id
        assigns(:import).should eql(import)
      end
    end
  end
end
