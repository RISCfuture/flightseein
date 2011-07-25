source 'http://rubygems.org'

# FRAMEWORK
gem 'rake', '< 0.9'
gem 'rails', '3.1.0.rc4'
gem 'configoro'

# MODELS
gem 'email_validation'
gem 'enum_type'
gem 'has_metadata'
gem 'paperclip'
gem 'pg'
gem 'slugalicious'
gem 'find_or_create_on_scopes'

# VIEWS
gem 'sprockets', '= 2.0.0.beta.10' # Rails 3.1rc4 incompatible with latest sprockets
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
  gem 'factory_girl', '2.0.0.beta2'
  gem 'faker'
  gem 'nokogiri'
end

group :production do
  # EXECJS
  gem 'therubyracer', require: 'v8'

  # CACHING
  gem 'memcache-client'
end
