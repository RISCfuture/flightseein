class CreateDestinations < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TABLE destinations (
        logbook_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        airport_id INTEGER NOT NULL REFERENCES airports(id) ON DELETE RESTRICT,
        metadata_id INTEGER REFERENCES metadata(id) ON DELETE CASCADE,
        has_photo BOOLEAN NOT NULL DEFAULT FALSE,
        flights_count INTEGER NOT NULL DEFAULT 0
        --PRIMARY KEY(user_id, airport_id)
      )
    SQL

    execute "CREATE UNIQUE INDEX destinations_pkey ON destinations(user_id, airport_id)"
    execute "CREATE UNIQUE INDEX destinations_logbook_id ON destinations(user_id, logbook_id)"
  end

  def down
    drop_table :destinations
  end
end
