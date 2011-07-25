namespace :import do
  desc "Import airport data from a 56-day NASR subscription file (include NASR=/path/to/nasr/directory)"
  task(nasr: :environment) do
    require 'airport_importer'
    AirportImporter.new(ENV['NASR']).import
  end
end
