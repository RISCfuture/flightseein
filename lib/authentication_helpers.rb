# Mananges authentication for the application. Authentication is handled by the
# session: The ID of the logged-in user is stored in the session hash when
# authenticated.
#
# If this module is included in a controller, some methods will automatically be
# provided to its views.

module AuthenticationHelpers
  extend ActiveSupport::Concern

  included do
    helper_method(:logged_in?, :logged_out?, :current_user, :subdomain_owner?) if respond_to?(:helper_method)
  end

  # @return [true, false] Whether this session is authenticated.

  def logged_in?
    not current_user.nil?
  end

  # @return [true, false] Whether or not the user is logged in and the owner of
  #   the current subdomain.

    def subdomain_owner?
      logged_in? and current_user.id == subdomain_owner.try(:id)
    end

  # @return [true, false] If this session is unauthenticated.

  def logged_out?
    not logged_in?
  end

  # @return [User, nil] The currently logged-in user, or `nil` for
  #   unauthenticated sessions.

  def current_user
    @current_user ||= begin
      if session[:user_id] then
        user = User.active.find_by_id(session[:user_id])
        session[:user_id] = nil if user.nil?
        user
      else
        nil
      end
    end
  end

  # Logs a user in. No authentication is performed; you must check the password
  # before calling this method.
  #
  # @param [User] user A user to log in.

  def log_in(user)
    session[:user_id] = user.id
    remove_instance_variable(:@current_user) if instance_variable_defined?(:@current_user)
  end

  # Logs the current user out. Future sessions are unauthenticated.

  def log_out
    session[:user_id] = nil
    remove_instance_variable(:@current_user) if instance_variable_defined?(:@current_user)
  end

  protected

  # `before_filter` that only allows authenticated users. Unauthenticated users
  # will be redirected to the {SessionsController#new} action.

  def login_required
    if logged_in? then
      return true
    else
      redirect_to new_session_url(subdomain: false), notice: t('controllers.application.login_required.notice')
      return false
    end
  end

  # `before_filter` that only allows the authenticated owner of the current
  # subdomain. Unauthenticated users will be redirected to the
  # {SessionsController#new} action.

  def owner_login_required
    if subdomain_owner? then
      return true
    elsif logged_in? then
      redirect_to root_url(subdomain: current_user.subdomain), alert: t('controllers.application.owner_login_required.not_owner')
    else
      redirect_to new_session_url(subdomain: false), notice: t('controllers.application.login_required.notice')
      return false
    end
  end

  # `before_filter` that only allows unauthenticated users. Authenticated users
  # will be redirected to the root URL.

  def login_disallowed
    if logged_in? then
      redirect_to root_url(subdomain: current_user.subdomain)
      return false
    else
      return true
    end
  end
end
