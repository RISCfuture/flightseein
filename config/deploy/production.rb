set :stage, :production

role :app, %w{www-data@www.flightsee.in}
role :web, %w{www-data@www.flightsee.in}
role :db,  %w{www-data@www.flightsee.in}
