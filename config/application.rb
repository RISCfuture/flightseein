require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Flightseein
  class Application < Rails::Application
    # Framework
    config.time_zone = 'Pacific Time (US & Canada)'
    config.autoload_paths << Rails.root.join('lib', 'workers')

    # Models
    config.active_record.schema_format = :sql

    # Development
    config.generators do |g|
      g.test_framework :rspec, fixture: true, views: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
  end
end

# Subdomain routing

SubdomainRouter::Config.domain            = 'flightsee.in' if Rails.env.production? || Rails.env.deploy?
SubdomainRouter::Config.subdomain_matcher = lambda do |subdomain, request|
  user                                            = Rails.cache.fetch("User/#{subdomain}") do
    User.active.for_subdomain(subdomain).first.try!(:id)
  end
  request.env['subdomain_router.subdomain_owner'] = user
  user
end

Dir.glob(Rails.root.join('lib', 'parser', '*.rb')).each { |f| require f }
