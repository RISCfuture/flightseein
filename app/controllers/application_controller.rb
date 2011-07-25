require 'subdomain_router'
require 'authentication_helpers'

# @abstract
#
# Superclass for all controllers in this application.

class ApplicationController < ActionController::Base
  include SubdomainRouter::Controller
  include AuthenticationHelpers

  protect_from_forgery
  layout 'application'

  rescue_from(ActiveRecord::RecordNotFound) { render(file: Rails.root.join('public', '404.html'), status: :not_found) }
  rescue_from(ActiveRecord::RecordInvalid) { render(file: Rails.root.join('public', '422.html'), status: :unprocessable_entity) }
end
