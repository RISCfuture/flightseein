class RemoveCrewColumnsFromFlights < ActiveRecord::Migration[4.2]
  def up
    execute "ALTER TABLE flights DROP pic_id, DROP sic_id"
    drop_table :flights_passengers
    drop_table :flights_people
  end

  def down
    execute "ALTER TABLE flights ADD pic_id INTEGER REFERENCES people(id) ON DELETE RESTRICT, ADD sic_id INTEGER REFERENCES people(id) ON DELETE RESTRICT"

    execute <<-SQL
      CREATE TABLE flights_passengers (
        flight_id INTEGER NOT NULL REFERENCES flights(id) ON DELETE CASCADE,
        person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE RESTRICT--,
        --PRIMARY KEY (flight_id, person_id)
      )
    SQL
    execute "CREATE UNIQUE INDEX flights_passengers_pkey ON flights_passengers(flight_id, person_id)"

    execute <<-SQL
      CREATE TABLE flights_people (
        flight_id INTEGER NOT NULL REFERENCES flights(id) ON DELETE CASCADE,
        person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE RESTRICT--,
        --PRIMARY KEY (flight_id, person_id)
      )
    SQL
    execute "CREATE UNIQUE INDEX flights_people_pkey ON flights_people(flight_id, person_id)"
  end
end
