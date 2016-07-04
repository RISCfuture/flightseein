class CreateOccupants < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      CREATE TABLE occupants (
        id SERIAL PRIMARY KEY,
        flight_id INTEGER NOT NULL REFERENCES flights(id) ON DELETE CASCADE,
        person_id INTEGER NOT NULL REFERENCES people(id) ON DELETE RESTRICT,
        role CHARACTER VARYING(126) DEFAULT NULL
      )
    SQL

    execute "CREATE INDEX occupants_person ON occupants(person_id)"
    execute "CREATE INDEX occupants_flight ON occupants(flight_id)"
  end

  def down
    drop_table :occupants
  end
end
