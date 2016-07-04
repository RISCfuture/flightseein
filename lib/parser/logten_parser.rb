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
    @destination_ids = Hash.new
    @person_ids = Hash.new
    @flight_ids = Hash.new

    Rails.logger.tagged(self.class.name) do
      import_aircraft
      import_airports
      import_passengers
      import_flights
      import_certificates
    end
  rescue ActiveRecord::RecordInvalid => err
    Rails.logger.error "Invalid record: #{err.record.errors.inspect}"
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
        Rails.logger.warn "Skipping ZAIRCRAFT due to blank ident: #{[ident, type, year, make, model, notes, image_path].inspect}"
        next
      end
      # year is stored as a seconds offset from 2001
      year = 2001 + year/31536000 if year
      long_type = model.present? ? "#{make} #{model}".strip : nil
      image = if image_path.present? then
                image_path = File.join(@path, image_path)
                File.exist?(image_path) ? open(image_path) : nil
              else
                nil
              end
      user.aircraft.where(ident: ident).create_or_update!(year: year, type: type, long_type: long_type, notes: notes, image: image)
      image&.close
    end
  end

  def import_airports
    importing_airports!

    rows = @db.execute <<-SQL
      SELECT ZPLACE.Z_PK, ZPLACE_FAAID, ZPLACE_ICAOID, ZPLACE_IATAID, ZLOGTENPROPERTY_IMAGEPATH
        FROM ZPLACE
        LEFT JOIN ZPLACEPROPERTY ON ZPLACE = ZPLACE.Z_PK AND ZLOGTENPROPERTY_KEY = 'place_image1'
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
        Rails.logger.warn "Skipping ZPLACE due to missing airport: #{[id, lid, icao, iata, image_path].inspect}"
        next
      end

      destination = user.destinations.where(airport_id: airport.id).create_or_update!(photo: image)
      image&.close
      @destination_ids[id] = destination
    end
  end

  def import_passengers
    importing_passengers!

    rows = @db.execute <<-SQL
      SELECT ZPERSON.Z_PK, ZPERSON.ZLOGTEN_UNIQUEID,
             ZPERSON_FULLNAME, ZPERSON_NAME, ZLOGTENPROPERTY_IMAGEPATH, ZPERSON_ISORGANIZATION, ZPERSON_ISME
        FROM ZPERSON
        LEFT JOIN ZPERSONPROPERTY ON ZPERSONPROPERTY.ZPERSON = ZPERSON.Z_PK;
    SQL

    rows.each do |(pkey, uuid, name1, name2, image_path, is_org, is_me)|
      next if is_org.parse_bool
      image = if image_path.present? then
                image_path = File.join(@path, image_path)
                File.exist?(image_path) ? open(image_path) : nil
              else
                nil
              end
      name = name1.present? ? name1 : name2

      person = nil
      Person.transaction do
        # first try to find by the UUID
        person = user.people.where(logbook_id: uuid).first
        # legacy: Z_PK
        person ||= user.people.where(logbook_id: pkey.to_s).first
        # or create a new one
        person ||= user.people.build
        # in any case, update the logbook ID to the new UUID system
        person.update_attributes!(logbook_id: uuid, name: name, photo: image, me: is_me.parse_bool)
        image&.close
      end

      @person_ids[pkey] = person
    end
  end

  def import_flights
    importing_flights!

    import_flight_records
    import_flight_pics
    import_flight_sics
    import_flight_pax

    user.destinations.each(&:update_flights_count!)
    user.people.each(&:update_hours!)
    user.update_hours!
    user.update_flight_sequence!
  end

  def import_flight_records
    rows = @db.execute <<-SQL
      SELECT ZFLIGHT.Z_PK, ZFLIGHT.ZLOGTEN_UNIQUEID,
             ZFLIGHT_TOTALTIME, ZFLIGHT_REMARKS,
             ZAIRCRAFT_AIRCRAFTID, ZFLIGHT_FROMPLACE,
             ZFLIGHT_TOPLACE, ZFLIGHT_FLIGHTDATE, ZFLIGHT_ROUTE
        FROM ZFLIGHT
        LEFT JOIN ZAIRCRAFT ON ZAIRCRAFT.Z_PK = ZFLIGHT_AIRCRAFT
    SQL

    rows.each do |(pkey, uuid, duration, remarks, ident, origin_id, destination_id, time, route)|
      aircraft = user.aircraft.where(ident: ident).first
      unless aircraft
        Rails.logger.warn "Skipping ZFLIGHT due to missing aircraft: #{[pkey, duration, remarks, ident, origin_id, destination_id].inspect}"
        next
      end

      origin = @destination_ids[origin_id]
      unless origin
        Rails.logger.warn "Skipping ZFLIGHT due to missing origin: #{[pkey, duration, remarks, ident, origin_id, destination_id].inspect}"
        next
      end

      destination = @destination_ids[destination_id]
      unless destination
        Rails.logger.warn "Skipping ZFLIGHT due to missing destination: #{[pkey, duration, remarks, ident, origin_id, destination_id].inspect}"
        next
      end

      date = Time.utc(2001).advance(seconds: time).utc.to_date

      if duration.nil? then
        Rails.logger.warn "Skipping ZFLIGHT due to nil duration: #{[pkey, duration, remarks, ident, origin_id, destination_id].inspect}"
        next
      end
      duration = duration/60.0
      if duration <= 0.0 then
        Rails.logger.warn "Skipping ZFLIGHT due to invalid duration: #{[pkey, duration, remarks, ident, origin_id, destination_id].inspect}"
        next
      end

      flight = nil
      Flight.transaction do
        # first try to find by the UUID
        flight = user.flights.where(logbook_id: uuid).first
        # legacy: Z_PK
        flight ||= user.flights.where(logbook_id: pkey.to_s).first
        # or create a new one
        flight ||= user.flights.build
        # in any case, update the logbook ID to the new UUID system
        flight.update_attributes!(logbook_id: uuid, duration: duration, remarks: remarks.try(:chomp).try(:strip), aircraft: aircraft, origin: origin, destination: destination, date: date)
      end
      @flight_ids[pkey] = flight

      flight.occupants.clear

      Stop.where(flight_id: flight.id).delete_all
      if route.present? then
        route.split('-')
        route.split('-')[1..-2].each_with_index do |stop, index|
          airport = Airport.with_ident(stop, stop, stop).first
          unless airport
            Rails.logger.warn "Skipping unknown route ident #{stop}"
            next
          end
          destination = user.destinations.where(airport_id: airport.id).find_or_create!
          begin
            flight.stops.create!(destination: destination, sequence: index + 1)
          rescue ActiveRecord::RecordNotUnique
            Rails.logger.warn "Skipping duplicate stop on ZFLIGHT: #{[flight, destination, index + 1].inspect}"
          end
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
      flight = @flight_ids[flight_id]
      unless flight
        Rails.logger.warn "Skipping ZPIC due to missing flight: #{[flight_id, person_id].inspect}"
        next
      end
      person = @person_ids[person_id]
      unless person
        Rails.logger.warn "Skipping ZPIC due to missing person: #{[flight_id, person_id].inspect}"
        next
      end
      flight.occupants.create!(role: "Pilot in command", person: person)
    end
  end

  def import_flight_sics
    rows = @db.execute <<-SQL
      SELECT ZPERSON, ZFLIGHT
        FROM ZSIC
    SQL

    rows.each do |(person_id, flight_id)|
      next unless person_id and flight_id
      flight = @flight_ids[flight_id]
      unless flight
        Rails.logger.warn "Skipping ZSIC due to missing flight: #{[flight_id, person_id].inspect}"
        next
      end
      person = @person_ids[person_id]
      unless person
        Rails.logger.warn "Skipping ZSIC due to missing person: #{[flight_id, person_id].inspect}"
        next
      end
      flight.occupants.create!(role: "Second in command", person: person)
    end
  end

  def import_flight_pax
    rows = @db.execute <<-SQL
      SELECT ZPAX_FLIGHT, ZPAX_PERSON
        FROM ZPASSENGER
    SQL

    rows.each do |(flight_id, person_id)|
      next unless person_id and flight_id
      flight = @flight_ids[flight_id]
      unless flight
        Rails.logger.warn "Skipping ZPASSENGER due to missing flight: #{[flight_id, person_id].inspect}"
        next
      end
      person = @person_ids[person_id]
      unless person
        Rails.logger.warn "Skipping ZPASSENGER due to missing person: #{[flight_id, person_id].inspect}"
        next
      end
      flight.occupants.create!(person: person)
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
