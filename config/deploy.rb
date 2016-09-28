lock '3.6.1'

set :application, 'flightseein'
set :repo_url, 'timothymorgan.git:flightseein.git'

set :deploy_to, '/var/www/www.flightsee.in'
set :rvm_ruby_version, "2.3.1@#{fetch :application}"

set :linked_files, %w{config/secrets.yml config/environments/production/paperclip.yml}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/assets}

namespace :deploy do
  after :finishing, 'deploy:restart'
  after :finishing, 'deploy:cleanup'
end
