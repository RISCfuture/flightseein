set :stage, :production

role :app, %w{www-data@www.flightsee.in}
role :web, %w{www-data@www.flightsee.in}
role :db,  %w{www-data@www.flightsee.in}

# http://blog.manzhikov.com/new-passenger-restart-in-5-version
set :rvm_map_bins, fetch(:rvm_map_bins, []).push('rvmsudo')
set :passenger_restart_command, 'rvmsudo passenger-config restart-app'
