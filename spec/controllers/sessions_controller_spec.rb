require 'rails_helper'

describe SessionsController, type: :controller do
  render_views

  describe "#new" do
    it "should render the login form" do
      get :new
      expect(response).to render_template('new')
    end

    it "should redirect if the user is already logged in" do
      user = FactoryBot.create(:user)
      get :new, session: {user_id: user.id}
      expect(response).to redirect_to(root_url(subdomain: user.subdomain))
    end
  end

  describe "#create" do
    before :each do
      @user = FactoryBot.create(:user)
    end

    it "should log the user out if credentials are incorrect" do
      session[:user_id] = FactoryBot.create(:user).id
      post :create, params: {user: {email: @user.email, password: 'wrong'}}
      expect(session[:user_id]).to be_nil
    end

    context "[incorrect credentials]" do
      before :each do
        post :create, params: {user: {email: @user.email, password: 'wrong'}}
      end

      it "should render the login form" do
        expect(response).to render_template('new')
      end

      it "should not log the user in" do
        expect(session[:user_id]).to be_nil
      end

      it "should use the existing field values if set, except the password" do
        html = Nokogiri::HTML(response.body)

        tags = html.css('form input[type=email]')
        expect(tags.size).to eql(1)
        expect(tags.first['value']).to eql(@user.email)

        tags = html.css('form input[type=password]')
        expect(tags.size).to eql(1)
        expect(tags.first['value']).to be_nil
      end
    end

    context "[correct credentials]" do
      before :each do
        post :create, params: {user: {email: @user.email, password: 'password'}}
      end

      it "should log the user in" do
        expect(session[:user_id]).to eql(@user.id)
      end

      it "should redirect to the root URL" do
        expect(response).to redirect_to root_url(subdomain: @user.subdomain)
      end
    end
  end

  describe "#destroy" do
    it "should redirect if the user is not logged in" do
      delete :destroy
      expect(response).to redirect_to(root_url)
    end

    it "should log the user out and redirect to the root URL" do
      delete :destroy, session: {user_id: FactoryBot.create(:user).id}
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_url)
    end
  end
end
