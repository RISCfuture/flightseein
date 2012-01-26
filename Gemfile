source 'http://rubygems.org'

# FRAMEWORK
gem 'rake'
gem 'rails', '>= 3.2'
gem 'configoro'

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

# VIEWS
gem 'coffee-script'
gem 'compass', '0.11.4', require: false # 0.11.5 has a bug in the reset module
gem 'jquery-rails'
gem 'sass'
gem 'uglifier'
gem 'redcarpet'#, require: 'RedCarpet' # also for documentation

# IMPORTING
gem 'sqlite3'
gem 'resque'

# ASSETS
gem 'aws-s3', require: 'aws/s3'

group :development do
  # DEVELOPMENT
  gem 'rails3-generators'
  
  # DEPLOY
  gem 'capistrano'

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
  # EXECJS
  gem 'therubyracer', require: 'v8'

  # CACHING
  gem 'memcache-client'
end
