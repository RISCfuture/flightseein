source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# FRAMEWORK
gem 'rake'
gem 'rails', '5.1.6'
gem 'configoro'

# CONTROLLERS
gem 'responders'

# ROUTING
gem 'subdomain_router'

# MIDDLEWARE
gem 'user-agent'

# MODELS
gem 'email_validation'
gem 'has_metadata_column', '>= 1.1.7'
gem 'paperclip'
gem 'aws-sdk-s3'
gem 'pg', '< 1.0'
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
gem 'zipruby'

# CRON
gem 'whenever'

# ASSETS
gem 'therubyracer', require: 'v8'
gem 'autoprefixer-rails'
gem 'sass-rails'
gem 'uglifier'
gem 'coffee-rails'
gem 'turbolinks'

# ERROR TRACKING
gem 'bugsnag'

# OTHER
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :development do
  gem 'puma'
  gem 'listen'

  # DEPLOY
  gem 'capistrano', require: false
  gem 'capistrano-rvm', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-sidekiq', require: false
  gem 'capistrano-passenger', require: false
  gem 'bugsnag-capistrano', require: false

  # DOCUMENTATION
  gem 'yard', require: false

  # ERRORS
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :test do
  # SPECS
  gem 'rspec-rails'
  gem 'rails-controller-testing'
  gem 'rspec-activejob'

  # FACTORIES/DB
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'database_cleaner'

  gem 'nokogiri'
end

group :production do
  # CACHING
  gem 'redis-rails'
  gem 'redis-rack-cache'
end
