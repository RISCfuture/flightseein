source 'https://rubygems.org'

# FRAMEWORK
gem 'rake'
gem 'rails', '4.2.0'
gem 'configoro'
gem 'responders'

# ROUTING
gem 'subdomain_router'

# MIDDLEWARE
gem 'user-agent'

# MODELS
gem 'email_validation'
gem 'enum_type'
gem 'has_metadata_column'
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
gem 'slim'
# if you require 'sinatra' you get the DSL extended to Object
gem 'sinatra', require: nil
gem 'zipruby'

# CRON
gem 'whenever'

# ASSETS
gem 'aws-s3', require: 'aws/s3'
gem 'aws-sdk'
gem 'therubyracer', require: 'v8'
gem 'autoprefixer-rails'
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'

group :development do
  # DEVELOPMENT
  gem 'rails3-generators'
  gem 'spring'
  gem 'web-console'

  # DEPLOY
  gem 'capistrano', require: nil
  gem 'capistrano-rvm', require: nil
  gem 'capistrano-bundler', require: nil
  gem 'capistrano-rails', require: nil
  gem 'capistrano-sidekiq', require: nil
  gem 'capistrano-passenger', require: nil

  # DOCUMENTATION
  gem 'yard', require: nil
end

group :test do
  # SPECS
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'nokogiri'
  gem 'database_cleaner'
end

group :production do
  # CACHING
  gem 'dalli'
end
