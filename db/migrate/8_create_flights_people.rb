class CreateFlightsPeople < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      CREATE TABLE flights_people (
        flight_id INTEGER NOT NULL REFERENCES flights(id) ON DELETE CASCADE,
        person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE RESTRICT--,
        --PRIMARY KEY (flight_id, person_id)
      )
    SQL

    execute "CREATE UNIQUE INDEX flights_people_pkey ON flights_people(flight_id, person_id)"
  end

  def down
    drop_table :flights_people
  end
end
