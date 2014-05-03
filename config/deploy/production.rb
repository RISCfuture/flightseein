set :stage, :production

set :rvm_type, :system
set :rvm_ruby_version, '2.1.1@flightseein'

role :app, %w{www-data@www.flightsee.in}
role :web, %w{www-data@www.flightsee.in}
role :db,  %w{www-data@www.flightsee.in}
