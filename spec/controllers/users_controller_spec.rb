require 'spec_helper'

describe UsersController do
  render_views
  
  describe "#new" do
    it "should redirect to the root URL if the user is already logged in" do
      user = Factory(:user)
      session[:user_id] = user.id
      get :new
      response.should redirect_to(root_url(subdomain: user.subdomain))
    end

    it "should render the signup form" do
      get :new
      response.should render_template('new')
    end
  end

  describe "#create" do
    it "should redirect to the root URL if the user is already logged in" do
      user = Factory(:user)
      session[:user_id] = user.id
      post :create, user: {}
      response.should redirect_to(root_url(subdomain: user.subdomain))
    end

    context "[valid values]" do
      before :each do
        @template = Factory.build(:user)
        post :create, user: @template.attributes.slice('email', 'subdomain').merge('password' => 'password')
      end

      it "should create the new user" do
        user = User.find_by_email(@template.email)
        user.should_not be_nil
        user.subdomain.should eql(@template.subdomain)
        user.authenticated?('password').should be_true
      end

      it "should log the new user in" do
        user = User.find_by_email(@template.email)
        session[:user_id].should eql(user.id)
      end

      it "should redirect to the account URL" do
        user = User.find_by_email(@template.email)
        response.should redirect_to(root_url(subdomain: @template.subdomain))
      end
    end

    context "[invalid values]" do
      before :each do
        @template = Factory.build(:user)
        post :create, user: @template.attributes.slice('email').merge('password' => 'something')
      end

      it "should render the signup form" do
        response.should render_template('new')
      end

      it "should preserve existing values except the password" do
        html = Nokogiri::HTML(response.body)

        tags = html.css('form input#user_email')
        tags.size.should eql(1)
        tags.first['value'].should eql(@template.email)

        tags = html.css('form input#user_password')
        tags.size.should eql(1)
        tags.first['value'].should be_nil
      end

      it "should not log any user in" do
        session[:user_id].should be_nil
      end
    end
  end
end
