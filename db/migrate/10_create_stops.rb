class CreateStops < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TABLE stops (
        destination_id INTEGER NOT NULL,
        flight_id INTEGER NOT NULL REFERENCES flights(id) ON DELETE CASCADE,
        sequence INTEGER NOT NULL CHECK (sequence >= 1)
        --PRIMARY KEY (destination_id, flight_id)
      )
    SQL

    execute "CREATE UNIQUE INDEX stops_pkey ON stops(destination_id, flight_id)"
    execute "CREATE INDEX stops_in_sequence ON stops(flight_id, sequence)"
  end

  def down
    drop_table :destinations
  end
end
