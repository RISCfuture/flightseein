require 'rails_helper'

describe UsersController, type: :controller do
  render_views

  describe "#new" do
    it "should redirect to the root URL if the user is already logged in" do
      user = FactoryGirl.create(:user)
      get :new, session: {user_id: user.id}
      expect(response).to redirect_to(root_url(subdomain: user.subdomain))
    end

    it "should render the signup form" do
      get :new
      expect(response).to render_template('new')
    end
  end

  describe "#create" do
    it "should redirect to the root URL if the user is already logged in" do
      user = FactoryGirl.create(:user)
      session[:user_id] = user.id
      post :create, params: {user: {}}
      expect(response).to redirect_to(root_url(subdomain: user.subdomain))
    end

    context "[valid values]" do
      before :each do
        @template = FactoryGirl.build(:user)
        post :create, params: {user: @template.attributes.slice('email', 'subdomain').merge('password' => 'password')}
      end

      it "should create the new user" do
        user = User.find_by_email(@template.email)
        expect(user).not_to be_nil
        expect(user.subdomain).to eql(@template.subdomain)
        expect(user.authenticated?('password')).to be(true)
      end

      it "should log the new user in" do
        user = User.find_by_email(@template.email)
        expect(session[:user_id]).to eql(user.id)
      end

      it "should redirect to the account URL" do
        user = User.find_by_email(@template.email)
        expect(response).to redirect_to(root_url(subdomain: @template.subdomain))
      end
    end

    context "[invalid values]" do
      before :each do
        @template = FactoryGirl.build(:user)
        post :create, params: {user: @template.attributes.slice('email').merge('password' => 'something')}
      end

      it "should render the signup form" do
        expect(response).to render_template('new')
      end

      it "should preserve existing values except the password" do
        html = Nokogiri::HTML(response.body)

        tags = html.css('form input[type=email]')
        expect(tags.size).to eql(1)
        expect(tags.first['value']).to eql(@template.email)

        tags = html.css('form input[type=password]')
        expect(tags.size).to eql(1)
        expect(tags.first['value']).to be_nil
      end

      it "should not log any user in" do
        expect(session[:user_id]).to be_nil
      end
    end
  end
end
