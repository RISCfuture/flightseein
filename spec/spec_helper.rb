# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path(File.join('..', '..', 'config', 'environment'), __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }
Dir[Rails.root.join('spec', 'factories', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = true

  config.before(:all) do
    Flight.find_each { |flight| flight.people.clear }
    Flight.find_each { |flight| flight.passengers.clear }
    User.delete_all # allows us to delete airports
    Airport.delete_all # prevents FADDS number conflicts
  end

  config.after(:all) do
    # clear out temporary downloaded files
    #Dir.glob(Rails.root.join('tmp', 'work', '*')).each { |file| FileUtils.rm_rf file }
  end
end
