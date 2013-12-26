source 'https://rubygems.org'

# FRAMEWORK
gem 'rake'
gem 'rails', '4.0.2'
gem 'configoro'

# ROUTING
gem 'subdomain_router'

# MIDDLEWARE
gem 'user-agent'

# MODELS
gem 'email_validation'
gem 'enum_type'
gem 'has_metadata'
gem 'paperclip'
gem 'pg'
gem 'slugalicious'
gem 'find_or_create_on_scopes'
gem 'paperclip_duplicate_check'

# VIEWS
gem 'jquery-rails'
gem 'redcarpet'#, require: 'RedCarpet' # also for documentation
gem 'carousel'
gem 'multiuploader'

# IMPORTING
gem 'sqlite3'
gem 'sidekiq'
gem 'slim', '>= 1.1.0'
# if you require 'sinatra' you get the DSL extended to Object
gem 'sinatra', '>= 1.3.0', require: nil

# ASSETS
gem 'aws-s3', require: 'aws/s3'
gem 'aws-sdk'
gem 'therubyracer', require: 'v8'
gem 'compass-rails', github: 'Compass/compass-rails'
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'

group :development do
  # DEVELOPMENT
  gem 'rails3-generators'

  # DEPLOY
  gem 'capistrano', require: nil
  gem 'capistrano-rvm', require: nil
  gem 'capistrano-bundler', require: nil
  gem 'capistrano-rails', require: nil

  # DOCUMENTATION
  gem 'yard', require: nil
end

group :test do
  # SPECS
  gem 'rspec-rails'
  gem 'factory_girl'
  gem 'faker'
  gem 'nokogiri'
end

group :production do
  # CACHING
  gem 'dalli'
end
