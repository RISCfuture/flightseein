# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

require 'airport_importer'

BASE_DATE = Date.civil(2014, 2, 6)

date = BASE_DATE
until date + 56 > Date.today
  date += 56
end
url = URI.parse("https://nfdc.faa.gov/webContent/56DaySub/#{date.strftime '%Y-%m-%d'}/APT.zip")

puts "Downloading NASR airport data..."
zipped_data = Net::HTTP.get(url)

puts "Unzipping airport data..."
Zip::Archive.open_buffer(zipped_data) do |zf|
  # this is a single file archive, so read the first file
  zf.fopen(zf.get_name(0)) do |f|
    airport_data = f.read
    puts "Importing airport data..."
    AirportImporter.import_data airport_data
  end
end

puts "Done with import."
