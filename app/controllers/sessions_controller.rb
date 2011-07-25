# Controller for logging into and out of the website.

class SessionsController < ApplicationController
  before_filter :login_disallowed, only: [ :new ]
  respond_to :html

  # Displays a page where a user can log in.
  #
  # Routes
  # ------
  #
  # * `GET /sessions`

  def new
    respond_with(@user ||= User.new)
  end

  # Authenticates a user and logs him in. The user will be taken to the
  # root URL if successful. If unsuccessful, the form will be re-rendered with
  # an error.
  #
  # Logs any existing session out before doing this.
  #
  # Routes
  # ------
  #
  # * `POST /sessions`
  #
  # Parameters
  # --------------------
  #
  # |                  |                                    |
  # |:-----------------|:-----------------------------------|
  # | `user[email]`    | The email to authenticate with.    |
  # | `user[password]` | The password to authenticate with. |

  def create
    log_out

    @user = User.with_email(params[:user][:email]).first
    if User.authenticated?(@user, params[:user][:password]) then
      log_in @user
      redirect_to root_url(subdomain: @user.subdomain), notice: t('controllers.sessions.create.success', name: @user.best_name)
    else
      flash[:alert] = t('controllers.sessions.create.bad_credentials')
      @user ||= User.new
      render 'new'
    end
  end

  # Logs a user out. Redirects to the root URL.
  #
  # Routes
  # ------
  #
  # * `DELETE /sessions`

  def destroy
    return redirect_to(root_url) if logged_out?
    log_out
    redirect_to root_url(subdomain: false), notice: t('controllers.sessions.destroy.logged_out')
  end
end
