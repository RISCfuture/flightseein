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

# BUNDLER

require 'bundler/capistrano'
