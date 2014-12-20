require 'subdomain_router'
require 'authentication_helpers'

# @abstract
#
# Superclass for all controllers in this application.

class ApplicationController < ActionController::Base
  include SubdomainRouter::Controller
  include AuthenticationHelpers

  # The User-Agent names of supported web browsers.
  SUPPORTED_BROWSERS = [ :Chrome, :chrome, :Safari, :safari ]

  protect_from_forgery
  layout 'application'
  before_action :warn_for_incompatible_browsers

  rescue_from(ActiveRecord::RecordNotFound) { render(file: Rails.root.join('public', '404.html'), status: :not_found) }
  rescue_from(ActiveRecord::RecordInvalid) { render(file: Rails.root.join('public', '422.html'), status: :unprocessable_entity) }

  protected

  # @return [User, nil] The user that owns the current subdomain, or `nil` for
  #   the default subdomain (e.g., "www").

  def subdomain_owner
    user_id = request.env['subdomain_router.subdomain_owner']
    user_id ? User.find(user_id) : User.active.for_subdomain(request.subdomain).first
  end
  helper_method :subdomain_owner

  private

  def warn_for_incompatible_browsers
    agent = Agent.new(request.env['HTTP_USER_AGENT'])
    @unsupported = !SUPPORTED_BROWSERS.include?(agent.name)
    return true
  end
end
