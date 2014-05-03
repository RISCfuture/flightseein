lock '3.2.1'

set :application, 'flightseein'
set :repo_url, 'git@www.timothymorgan.info:flightseein.git'

set :deploy_to, '/var/www/www.flightsee.in'

set :linked_files, %w{config/secrets.yml config/environments/production/paperclip.yml}
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/assets}

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp', 'restart.txt')
    end
  end

  after :finishing, 'deploy:restart'
  after :finishing, 'deploy:cleanup'
end
