class CreateFlights < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      CREATE TABLE flights (
        id SERIAL PRIMARY KEY,
        metadata_id INTEGER REFERENCES metadata(id) ON DELETE CASCADE,
        logbook_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        origin_id INTEGER NOT NULL,
        destination_id INTEGER NOT NULL,
        pic_id INTEGER REFERENCES people(id) ON DELETE RESTRICT,
        sic_id INTEGER REFERENCES people(id) ON DELETE RESTRICT,
        aircraft_id INTEGER NOT NULL REFERENCES aircraft(id) ON DELETE RESTRICT,
        duration FLOAT NOT NULL CHECK (duration > 0),
        "date" DATE NOT NULL,
        has_blog BOOLEAN NOT NULL DEFAULT FALSE,
        has_photos BOOLEAN NOT NULL DEFAULT FALSE,

        FOREIGN KEY (user_id, origin_id) REFERENCES destinations(user_id, airport_id) ON DELETE RESTRICT,
        FOREIGN KEY (user_id, destination_id) REFERENCES destinations(user_id, airport_id) ON DELETE RESTRICT
      )
    SQL

    execute "CREATE INDEX flights_user ON flights(user_id, date)"
    execute "CREATE INDEX flights_user_dest ON flights(user_id, destination_id, date)"
    execute "CREATE INDEX flights_user_blog ON flights(user_id, has_blog, date)"
    execute "CREATE INDEX flights_with_photos ON flights(has_photos, date)"
    execute "CREATE UNIQUE INDEX flights_logbook_id ON flights(user_id, logbook_id)"
  end

  def down
    drop_table :flights
  end
end
