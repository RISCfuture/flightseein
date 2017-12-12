require 'rails_helper'

describe ImportsController, type: :controller do
  describe "#new" do
    it "should redirect if no user is logged in" do
      get :new
      expect(response).to be_redirect
    end

    it "should redirect if the user is not the subdomain owner" do
      request.host = "#{FactoryBot.create(:user).subdomain}.test.host"
      get :new, session: {user_id: FactoryBot.create(:user).id}
      expect(response).to be_redirect
    end

    context "[subdomain owner]" do
      before :each do
        @user = FactoryBot.create(:user)
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
      post :create, params: {import: {}}
      expect(response).to be_redirect
    end

    it "should redirect if the user is not the subdomain owner" do
      request.host = "#{FactoryBot.create(:user).subdomain}.test.host"
      post :create, params: {import: {}}, session: {user_id: FactoryBot.create(:user).id}
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
          @attributes = FactoryBot.attributes_for(:import, user: @user, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'logten.zip'), 'application/zip'))
        end

        it "should create a new Import" do
          post :create, params: {import: @attributes}
          expect(@user.imports.count).to eql(1)
          import = @user.imports.first
          expect(import.logbook.original_filename).to eql('logten.zip')
        end

        it "should enqueue the Import" do
          post :create, params: {import: @attributes}
          expect(ImporterJob).to have_been_enqueued
        end

        it "should redirect to the import progress page" do
          post :create, params: {import: @attributes}
          expect(response).to redirect_to(@user.imports.first)
        end
      end

      context "[invalid values]" do
        before :each do
          @attributes = FactoryBot.attributes_for(:import, user: @user, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'bogus.txt'), 'text/plain'))
        end

        it "should move errors on the Paperclip aux fields to the main Paperclip field" do
          post :create, params: {import: @attributes}
          import = assigns(:import)
          expect(import.errors[:logbook]).not_to be_empty
          expect(import.errors[:logbook]).to eql(import.errors[:logbook_content_type])
        end

        it "should render the form" do
          post :create, params: {import: @attributes}
          expect(response).to render_template('new')
        end

        it "should set @import to the unsaved Import" do
          post :create, params: {import: @attributes}
          expect(assigns(:import)).to be_kind_of(Import)
          expect(assigns(:import)).to be_new_record
        end

        it "should not enqueue anything" do
          post :create, params: {import: @attributes}
          expect(ImporterJob).not_to have_been_enqueued
        end
      end
    end
  end

  describe "#show" do
    it "should redirect if no user is logged in" do
      get :show, params: {id: FactoryBot.create(:import).id}
      expect(response).to be_redirect
    end

    it "should redirect if the user is not the subdomain owner" do
      user = FactoryBot.create(:user)
      request.host = "#{FactoryBot.create(:user).subdomain}.test.host"
      get :show, params: {id: FactoryBot.create(:import, user: user).id}, session: {user_id: user.id}
      expect(response).to be_redirect
    end

    context "[subdomain owner]" do
      before :each do
        @user = FactoryBot.create(:user)
        session[:user_id] = @user.id
        request.host = "#{@user.subdomain}.test.host"
      end
      
      it "should 404 if the Import does not belong to the current user" do
        get :show, params: {id: FactoryBot.create(:import).id}
        expect(response.status).to eql(404)
      end

      it "should 404 if the Import is not found" do
        get :show, params: {id: 'not-found'}
        expect(response.status).to eql(404)
      end

      it "should set @import to the Import" do
        import = FactoryBot.create(:import, user: @user)
        get :show, params: {id: import.id}
        expect(assigns(:import)).to eql(import)
      end
    end
  end
end
