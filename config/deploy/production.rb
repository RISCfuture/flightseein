set :stage, :production

role :app, %w{deploy@www.flightsee.in}
role :web, %w{deploy@www.flightsee.in}
role :db,  %w{deploy@www.flightsee.in}
