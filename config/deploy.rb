lock '3.10.1'

set :application, 'flightseein'
set :repo_url, 'timothymorgan.git:flightseein.git'

set :deploy_to, '/var/www/www.flightsee.in'
set :rvm_ruby_version, "2.4.1@#{fetch :application}"

append :linked_files, 'config/secrets.yml', 'config/sidekiq.yml',
       'config/environments/production/paperclip.yml'
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets',
       'public/system'

set :sidekiq_config, 'config/sidekiq.yml'
