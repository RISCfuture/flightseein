source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# FRAMEWORK
gem 'rake'
gem 'rails', '5.1.3'
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
gem 'aws-sdk', '>= 2.0.34'
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

# OTHER
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :development do
  gem 'puma'
  gem 'listen'

  # DEPLOY
  gem 'capistrano', require: nil
  gem 'capistrano-rvm', require: nil
  gem 'capistrano-bundler', require: nil
  gem 'capistrano-rails', require: nil
  gem 'capistrano-sidekiq', require: nil
  gem 'capistrano-passenger', require: nil

  # DOCUMENTATION
  gem 'yard', require: nil

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
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'database_cleaner'

  gem 'nokogiri'
end

group :production do
  # CACHING
  gem 'redis-rails'
  gem 'rack-cache', require: 'rack/cache'
end
