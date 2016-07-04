class CreateAircraft < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      CREATE TABLE aircraft (
        id SERIAL PRIMARY KEY,
        metadata_id INTEGER REFERENCES metadata(id) ON DELETE CASCADE,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        ident CHARACTER VARYING(16) NOT NULL CHECK (CHAR_LENGTH(ident) > 0),
        has_image BOOLEAN NOT NULL DEFAULT FALSE
      )
    SQL

    execute "CREATE UNIQUE INDEX aircraft_ident ON aircraft(user_id, ident)"
  end

  def down
    drop_table :aircraft
  end
end
