class CreateFlightsPassengers < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TABLE flights_passengers (
        flight_id INTEGER NOT NULL REFERENCES flights(id) ON DELETE CASCADE,
        person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE RESTRICT--,
        --PRIMARY KEY (flight_id, person_id)
      )
    SQL

    execute "CREATE UNIQUE INDEX flights_passengers_pkey ON flights_passengers(flight_id, person_id)"
  end

  def down
    drop_table :flights_passengers
  end
end
