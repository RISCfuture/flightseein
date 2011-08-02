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
set :runner, 'apache'

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

# PERMISSIONS

namespace :permissions do
  task :chown, roles: :app do
    sudo "chown -R #{runner}:wheel #{release_path}"
  end
end
after "assets:precompile", "permissions:chown"

# BUNDLER

require 'bundler/capistrano'

# ASSETS

namespace :assets do
  task :precompile, roles: :app do
    run "cd #{release_path} && bundle exec rake assets:precompile RAILS_ENV=production"
  end
end
after "bundle:install", "assets:precompile"
