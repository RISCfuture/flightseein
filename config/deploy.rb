# GENERAL

set :application, 'www.flightsee.in'
set :repository, "gitosis@www.flightsee.in:flightseein.git"

# SCM

set :scm, :git
set :git_shallow_copy, true
set :branch, 'master'

# DEPLOY

set :deploy_to, File.join('', 'var', 'www', application)
set :deploy_via, :copy
set :copy_cache, true

# AUTHENTICATION

ssh_options[:forward_agent] = true
ssh_options[:keys] = %w{ ~/.ssh/id_rsa }

# USERS

set :user, 'tmorgan'
set :runner, 'www-data'

# ROLES

role :web, 'www.flightsee.in'
role :app, 'www.flightsee.in'
role :db, 'www.flightsee.in', primary: true

# PASSENGER

namespace :deploy do
   task :start do ; end
   task :stop do ; end
   task :restart, roles: :app, except: { no_release: true } do
     sudo "/etc/init.d/apache2 restart"
   end
end

# BUNDLER

require 'bundler/capistrano'

# ASSETS

load 'deploy/assets'

namespace :ownership do
  task(:fix_current) do
    sudo "chown -R www-data:sudo #{deploy_to}"
    sudo "chmod -R 777 #{release_path}/tmp"
  end
  task(:change_assets) { sudo "chown -R tmorgan:sudo #{shared_path}/assets" }
  task(:fix_assets) { sudo "chown -R www-data:sudo #{shared_path}/assets" }
end

before 'deploy:assets:update_asset_mtimes','ownership:change_assets'
after 'deploy:assets:update_asset_mtimes', 'ownership:fix_assets'
after 'deploy:finalize_update', 'ownership:fix_current'
after 'deploy:restart', 'ownership:fix_current' # twice for good luck?

# SIDEKIQ

set :sidekiq_cmd, "#{fetch :bundle_cmd, 'bundle'} exec sidekiq"
set :sidekiqctl_cmd, "#{fetch :bundle_cmd, 'bundle'} exec sidekiqctl"
require 'sidekiq/capistrano'
