require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require 'rails/all'

# If you have a Gemfile, require the default gems, the ones in the
# current environment and also include :assets gems if in development
# or test environments.
Bundler.require *Rails.groups(:assets) if defined?(Bundler)

module Flightseein
  class Application < Rails::Application
    # Framework
    config.time_zone = 'Pacific Time (US & Canada)'
    config.encoding = 'utf-8'
    config.autoload_paths << Rails.root.join('lib', 'workers')

    # Models
    config.active_record.schema_format = :sql

    # Controllers
#    config.action_dispatch.tld_length = Flightseein::Configuration.routing.tld_length

    # Views
    config.assets.enabled = true

    # Development
    config.generators do |g|
      g.test_framework :rspec, fixture: true, views: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
    end
  end
end
