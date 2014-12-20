# This controller lets users sign up for new accounts.

class UsersController < ApplicationController
  before_action :login_disallowed
  respond_to :html

  # Displays a form where a user can create a new account.
  #
  # Routes
  # ------
  #
  # * `GET /users/new`

  def new
    respond_with(@user ||= User.new)
  end

  # Creates a new user account.
  #
  # Routes
  # ------
  #
  # * `POST /users`
  #
  # Parameterized Hashes
  # --------------------
  #
  # |        |                                           |
  # |:-------|:------------------------------------------|
  # | `user` | The information for the new user account. |

  def create
    @user = User.create(user_params)
    log_in(@user) if @user.valid?
    respond_with @user do |format|
      format.html do
        if @user.valid? then
          redirect_to root_url(subdomain: @user.subdomain)
        else
          @flights = Flight.includes(:user, :slugs).where(has_photos: true).order('date DESC').limit(5)
          render 'new'
        end
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :name, :quote, :subdomain, :avatar)
  end
end
