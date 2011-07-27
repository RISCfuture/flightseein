require 'parser'

# A {Parser} that imports Coradine's LogTen Pro logbook files.

class LogtenParser < Parser
  # Ordered hash mapping LogTen names of certificate levels to internal I18n
  # keys. The hash is ordered by decreasing achievement level of the
  # certificate.
  IMPORTANT_CERTIFICATE_TYPES = {
    'Airline Transport' => 'atp',
    'Instructor' => 'cfi',
    'Commercial' => 'commercial',
    'Private' => 'private',
    'Recreational' => 'recreational',
    'Sport' => 'sport',
    'Student' => 'student'
  }

  def process
    @db = SQLite3::Database.new(File.join(@path, 'LogTenCoreDataStore.sql'))
    import_aircraft
    import_airports
    import_passengers
    import_flights
    import_certificates
  rescue ActiveRecord::RecordInvalid => err
    Rails.logger.error "[LogtenParser] Invalid record: #{err.record.errors.inspect}"
    raise
  end

  private

  def import_aircraft
    importing_aircraft!

    rows = @db.execute <<-SQL
      SELECT ZAIRCRAFT_AIRCRAFTID, ZAIRCRAFTTYPE_TYPE, ZAIRCRAFT_YEAR, ZAIRCRAFTTYPE_MAKE, ZAIRCRAFTTYPE_MODEL, ZAIRCRAFT_NOTES, ZLOGTENPROPERTY_IMAGEPATH
        FROM ZAIRCRAFT
        LEFT JOIN ZAIRCRAFTTYPE ON ZAIRCRAFTTYPE.Z_PK = ZAIRCRAFT_AIRCRAFTTYPE
        LEFT JOIN ZAIRCRAFTPROPERTY ON ZAIRCRAFTPROPERTY.ZAIRCRAFT = ZAIRCRAFT.Z_PK;
    SQL

    rows.each do |(ident, type, year, make, model, notes, image_path)|
      if ident.blank? then
        Rails.logger.warn "[LogtenParser] Skipping ZAIRCRAFT due to blank ident: #{[ident, type, year, make, model, notes, image_path].inspect}"
        next
      end
      # year is stored as a seconds offset from 2001
      year = 2001 + year/31536000
      long_type = model.present? ? "#{make} #{model}".strip : nil
      image = if image_path.present? then
                image_path = File.join(@path, image_path)
                File.exist?(image_path) ? open(image_path) : nil
              else
                nil
              end
      user.aircraft.where(ident: ident).create_or_update!(year: year, type: type, long_type: long_type, notes: notes, image: image)
    end
  end

  def import_airports
    importing_airports!

    rows = @db.execute <<-SQL
      SELECT ZPLACE.Z_PK, ZPLACE_FAAID, ZPLACE_ICAOID, ZPLACE_IATAID, ZLOGTENPROPERTY_IMAGEPATH
        FROM ZPLACE
        LEFT JOIN ZPLACEPROPERTY ON ZPLACE = ZPLACE.Z_PK
    SQL

    rows.each do |(id, lid, icao, iata, image_path)|
      image = if image_path.present? then
                image_path = File.join(@path, image_path)
                File.exist?(image_path) ? open(image_path) : nil
              else
                nil
              end
      airport = Airport.with_ident(lid, icao, iata).first
      unless airport
        Rails.logger.warn "[LogtenParser] Skipping ZPLACE due to missing airport: #{[id, lid, icao, iata, image_path].inspect}"
        next
      end
      user.destinations.where(logbook_id: id).create_or_update!(airport: airport, photo: image)
    end
  end

  def import_passengers
    importing_passengers!

    rows = @db.execute <<-SQL
      SELECT ZPERSON.Z_PK, ZPERSON_FULLNAME, ZPERSON_NAME, ZLOGTENPROPERTY_IMAGEPATH, ZPERSON_ISORGANIZATION, ZPERSON_ISME
        FROM ZPERSON
        LEFT JOIN ZPERSONPROPERTY ON ZPERSONPROPERTY.ZPERSON = ZPERSON.Z_PK;
    SQL

    rows.each do |(pkey, name1, name2, image_path, is_org, is_me)|
      next if is_org.parse_bool
      image = if image_path.present? then
                image_path = File.join(@path, image_path)
                File.exist?(image_path) ? open(image_path) : nil
              else
                nil
              end
      name = name1.present? ? name1 : name2
      user.people.where(logbook_id: pkey).create_or_update!(name: name, photo: image, me: is_me.parse_bool)
    end
  end

  def import_flights
    importing_flights!

    import_flight_records
    import_flight_pics
    import_flight_sics
    import_flight_pax

    user.flights.each(&:update_people!)
    user.destinations.each(&:update_flights_count!)
    user.people.each(&:update_hours!)
    user.update_hours!
  end

  def import_flight_records
    rows = @db.execute <<-SQL
      SELECT ZFLIGHT.Z_PK, ZFLIGHT_TOTALTIME, ZFLIGHT_REMARKS, ZFLIGHT_CREWPIC,
             ZFLIGHT_CREWSIC, ZAIRCRAFT_AIRCRAFTID, ZFLIGHT_FROMPLACE,
             ZFLIGHT_TOPLACE, ZFLIGHT_FLIGHTDATE, ZFLIGHT_ROUTE
        FROM ZFLIGHT
        LEFT JOIN ZAIRCRAFT ON ZAIRCRAFT.Z_PK = ZFLIGHT_AIRCRAFT
    SQL

    rows.each do |(pkey, duration, remarks, pic_id, sic_id, ident, origin_id, destination_id, time, route)|
      aircraft = user.aircraft.where(ident: ident).first
      unless aircraft
        Rails.logger.warn "[LogtenParser] Skipping ZFLIGHT due to missing aircraft: #{[pkey, duration, remarks, pic_id, sic_id, ident, origin_id, destination_id].inspect}"
        next
      end

      origin = user.destinations.where(logbook_id: origin_id).first
      unless origin
        Rails.logger.warn "[LogtenParser] Skipping ZFLIGHT due to missing origin: #{[pkey, duration, remarks, pic_id, sic_id, ident, origin_id, destination_id].inspect}"
        next
      end

      destination = user.destinations.where(logbook_id: destination_id).first
      unless destination
        Rails.logger.warn "[LogtenParser] Skipping ZFLIGHT due to missing destination: #{[pkey, duration, remarks, pic_id, sic_id, ident, origin_id, destination_id].inspect}"
        next
      end

      date = Time.utc(2001).advance(seconds: time).utc.to_date

      flight = user.flights.where(logbook_id: pkey).create_or_update!(duration: (duration/60.0), remarks: remarks.chomp.strip, aircraft: aircraft, origin: origin, destination: destination, date: date, pic: nil, sic: nil)
      flight.people.clear
      flight.passengers.clear

      Stop.delete_all(flight_id: flight.id)
      if route then
        route.split('-')[1..-2].each_with_index do |stop, index|
          airport = Airport.with_ident(stop, stop, stop).first
          unless airport
            Rails.logger.warn "[LogtenParser] Skipping unknown route ident #{stop}"
            next
          end
          destination = user.destinations.where(airport_id: airport.id).find_or_create!
          flight.stops.create!(destination: destination, sequence: index + 1)
        end
      end
    end
  end

  def import_flight_pics
    rows = @db.execute <<-SQL
      SELECT ZPERSON, ZFLIGHT
        FROM ZPIC
    SQL

    rows.each do |(person_id, flight_id)|
      next unless person_id and flight_id
      flight = user.flights.where(logbook_id: flight_id).first
      unless flight
        Rails.logger.warn "[LogtenParser] Skipping ZPIC due to missing flight: #{[flight_id, person_id].inspect}"
        next
      end
      person = user.people.where(logbook_id: person_id).first
      unless person
        Rails.logger.warn "[LogtenParser] Skipping ZPIC due to missing person: #{[flight_id, person_id].inspect}"
        next
      end
      flight.update_attribute :pic, person
    end
  end

  def import_flight_sics
    rows = @db.execute <<-SQL
      SELECT ZPERSON, ZFLIGHT
        FROM ZSIC
    SQL

    rows.each do |(person_id, flight_id)|
      next unless person_id and flight_id
      flight = user.flights.where(logbook_id: flight_id).first
      unless flight
        Rails.logger.warn "[LogtenParser] Skipping ZSIC due to missing flight: #{[flight_id, person_id].inspect}"
        next
      end
      person = user.people.where(logbook_id: person_id).first
      unless person
        Rails.logger.warn "[LogtenParser] Skipping ZSIC due to missing person: #{[flight_id, person_id].inspect}"
        next
      end
      flight.update_attribute :sic, person
    end
  end

  def import_flight_pax
    rows = @db.execute <<-SQL
      SELECT ZPAX_FLIGHT, ZPAX_PERSON
        FROM ZPASSENGER
    SQL

    rows.each do |(flight_id, person_id)|
      next unless person_id and flight_id
      flight = user.flights.where(logbook_id: flight_id).first
      unless flight
        Rails.logger.warn "[LogtenParser] Skipping ZPASSENGER due to missing flight: #{[flight_id, person_id].inspect}"
        next
      end
      person = user.people.where(logbook_id: person_id).first
      unless person
        Rails.logger.warn "[LogtenParser] Skipping ZPASSENGER due to missing person: #{[flight_id, person_id].inspect}"
        next
      end
      flight.passengers << person
    end
  end

  def import_certificates
    user.certificate = nil
    user.certification_date = nil

    rows = @db.execute <<-SQL
      SELECT ZCERTIFICATE_TYPE, ZCERTIFICATE_DATE
        FROM ZCERTIFICATE
    SQL

    types = rows.map(&:first)
    types.flatten!
    user.has_instrument = types.include?('Instrument')
    types.select! { |type| IMPORTANT_CERTIFICATE_TYPES.keys.include? type }
    if cert = IMPORTANT_CERTIFICATE_TYPES.keys.detect { |type| types.include?(type) } then
      user.certificate = IMPORTANT_CERTIFICATE_TYPES[cert]
      time = rows.detect { |(type, _)| cert == type }.last
      user.certification_date = Time.utc(2001).advance(seconds: time).utc.to_date
    end

    user.save!
  end
end
