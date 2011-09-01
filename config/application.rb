require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(assets: %w( development test ))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Flightseein
  class Application < Rails::Application
    # Framework
    config.time_zone = 'Pacific Time (US & Canada)'
    config.encoding = 'utf-8'
    config.autoload_paths << Rails.root.join('lib', 'workers')

    # Models
    config.active_record.schema_format = :sql

    # Controllers
    config.filter_parameters << :password
#    config.action_dispatch.tld_length = Flightseein::Configuration.routing.tld_length

    # Views
    config.assets.enabled = true
    config.assets.version = '1.0'
    config.assets.precompile += %w( ie.js )

    # Development
    config.generators do |g|
      g.test_framework :rspec, fixture: true, views: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end
  end
end
