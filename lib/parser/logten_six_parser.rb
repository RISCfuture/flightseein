require 'parser'

# A {Parser} that imports Coradine's LogTen 6 logbook files.

class LogtenSixParser < Parser
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
      person = user.people.where(logbook_id: uuid).create_or_update!(name: name, photo: image, me: is_me.parse_bool)

      @person_ids[pkey] = person
    end
  end

  def import_flights
    importing_flights!

    import_flight_records
    import_flight_crew
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
             ZAIRCRAFT_AIRCRAFTID,
             ZFLIGHT_FROMPLACE, ZFLIGHT_TOPLACE,
             ZFLIGHT_FLIGHTDATE, ZFLIGHT_ROUTE
        FROM ZFLIGHT
        LEFT JOIN ZAIRCRAFT ON ZAIRCRAFT.Z_PK = ZFLIGHT_AIRCRAFT
        ORDER BY ZFLIGHT_FLIGHTDATE ASC
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

      flight = user.flights.where(logbook_id: uuid).create_or_update!(duration: duration, remarks: remarks.try(:chomp).try(:strip), aircraft: aircraft, origin: origin, destination: destination, date: date)
      @flight_ids[pkey] = flight

      flight.occupants.clear

      Stop.delete_all(flight_id: flight.id)
      if route.present? then
        route.split('-').each_with_index do |stop, index|
          airport = Airport.with_ident(stop, stop, stop).first
          unless airport
            Rails.logger.warn "Skipping unknown route ident #{stop}"
            next
          end
          destination = user.destinations.where(airport_id: airport.id).first_or_create!
          begin
            flight.stops.create!(destination: destination, sequence: index + 1)
          rescue ActiveRecord::RecordNotUnique
            Rails.logger.warn "Skipping duplicate stop on ZFLIGHT: #{[flight, destination, index + 1].inspect}"
          end
        end
      end
    end
  end

  FLIGHT_CREW = [
      'Pilot in command',
      'Second in command',
      'Commander',
      'Flight attendant',
      'Flight attendant',
      'Flight attendant',
      'Flight attendant',
      'Engineer',
      'Flight instructor',
      'Observer',
      'Observer',
      'Relief pilot',
      'Relief pilot',
      'Relief pilot',
      'Relief pilot',
      'Student pilot'
  ]

  def import_flight_crew
    rows = @db.execute <<-SQL
      SELECT ZFLIGHTCREW_FLIGHT,
             ZFLIGHTCREW_PIC, ZFLIGHTCREW_SIC, ZFLIGHTCREW_COMMANDER,
             ZFLIGHTCREW_FLIGHTATTENDANT1, ZFLIGHTCREW_FLIGHTATTENDANT2,
             ZFLIGHTCREW_FLIGHTATTENDANT3, ZFLIGHTCREW_FLIGHTATTENDANT4,
             ZFLIGHTCREW_FLIGHTENGINEER, ZFLIGHTCREW_INSTRUCTOR,
             ZFLIGHTCREW_OBSERVER1, ZFLIGHTCREW_OBSERVER2,
             ZFLIGHTCREW_RELIEF1, ZFLIGHTCREW_RELIEF2, ZFLIGHTCREW_RELIEF3,
             ZFLIGHTCREW_RELIEF4, ZFLIGHTCREW_STUDENT, ZFLIGHTCREW_CUSTOM1,
             ZFLIGHTCREW_CUSTOM2, ZFLIGHTCREW_CUSTOM3, ZFLIGHTCREW_CUSTOM4,
             ZFLIGHTCREW_CUSTOM5
        FROM ZFLIGHTCREW
    SQL

    rows.each do |(flight_id, *crew)|
      next unless crew.any? and flight_id

      flight = @flight_ids[flight_id]
      unless flight
        Rails.logger.warn "Skipping ZFLIGHTCREW due to missing flight: #{flight_id}"
        next
      end

      crew.zip(FLIGHT_CREW).each do |(person_id, role)|
        next unless person_id
        role ||= "Crewmember"
        person = @person_ids[person_id]
        unless person
          Rails.logger.warn "Skipping ZFLIGHTCREW crewmember due to missing person: #{[flight_id, person_id].inspect}"
          next
        end
        flight.occupants.create!(person: person, role: role)
      end
    end
  end

  def import_flight_pax
    rows = @db.execute <<-SQL
      SELECT ZFLIGHTPASSENGERS_FLIGHT,
             ZFLIGHTPASSENGERS_PAX1,
             ZFLIGHTPASSENGERS_PAX2,
             ZFLIGHTPASSENGERS_PAX3,
             ZFLIGHTPASSENGERS_PAX4,
             ZFLIGHTPASSENGERS_PAX5,
             ZFLIGHTPASSENGERS_PAX6,
             ZFLIGHTPASSENGERS_PAX7,
             ZFLIGHTPASSENGERS_PAX8,
             ZFLIGHTPASSENGERS_PAX9,
             ZFLIGHTPASSENGERS_PAX10,
             ZFLIGHTPASSENGERS_PAX11,
             ZFLIGHTPASSENGERS_PAX12,
             ZFLIGHTPASSENGERS_PAX13,
             ZFLIGHTPASSENGERS_PAX14,
             ZFLIGHTPASSENGERS_PAX15,
             ZFLIGHTPASSENGERS_PAX16,
             ZFLIGHTPASSENGERS_PAX17,
             ZFLIGHTPASSENGERS_PAX18,
             ZFLIGHTPASSENGERS_PAX19,
             ZFLIGHTPASSENGERS_PAX20
        FROM ZFLIGHTPASSENGERS
    SQL

    rows.each do |(flight_id, *pax)|
      pax.compact!
      next unless pax.any? and flight_id

      flight = @flight_ids[flight_id]
      unless flight
        Rails.logger.warn "Skipping ZFLIGHTPASSENGERS due to missing flight: #{[flight_id].inspect}"
        next
      end

      pax.each do |person_id|
        person = @person_ids[person_id]
        unless person
          Rails.logger.warn "Skipping ZFLIGHTPASSENGERS due to missing person: #{[flight_id, person_id].inspect}"
          next
        end
        flight.occupants.create(person: person)
      end
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
