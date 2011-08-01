require 'spec_helper'

describe SessionsController do
  render_views

  describe "#new" do
    it "should render the login form" do
      get :new
      response.should render_template('new')
    end

    it "should redirect if the user is already logged in" do
      user = FactoryGirl.create(:user)
      session[:user_id] = user.id
      get :new
      response.should redirect_to(root_url(subdomain: user.subdomain))
    end
  end

  describe "#create" do
    before :each do
      @user = FactoryGirl.create(:user)
    end

    it "should log the user out if credentials are incorrect" do
      session[:user_id] = FactoryGirl.create(:user).id
      post :create, user: { email: @user.email, password: 'wrong' }
      session[:user_id].should be_nil
    end

    context "[incorrect credentials]" do
      before :each do
        post :create, user: { email: @user.email, password: 'wrong' }
      end

      it "should render the login form" do
        response.should render_template('new')
      end

      it "should not log the user in" do
        session[:user_id].should be_nil
      end

      it "should use the existing field values if set, except the password" do
        html = Nokogiri::HTML(response.body)

        tags = html.css('form input#user_email')
        tags.size.should eql(1)
        tags.first['value'].should eql(@user.email)

        tags = html.css('form input#user_password')
        tags.size.should eql(1)
        tags.first['value'].should be_nil
      end
    end

    context "[correct credentials]" do
      before :each do
        post :create, user: { email: @user.email, password: 'password' }
      end

      it "should log the user in" do
        session[:user_id].should eql(@user.id)
      end

      it "should redirect to the root URL" do
        response.should redirect_to root_url(subdomain: @user.subdomain)
      end
    end
  end

  describe "#destroy" do
    it "should redirect if the user is not logged in" do
      delete :destroy
      response.should redirect_to(root_url)
    end

    it "should log the user out and redirect to the root URL" do
      session[:user_id] = FactoryGirl.create(:user).id
      delete :destroy
      session[:user_id].should be_nil
      response.should redirect_to(root_url)
    end
  end
end
