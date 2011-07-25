class CreatePeople < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TABLE people (
        id SERIAL PRIMARY KEY,
        logbook_id INTEGER NOT NULL,
        metadata_id INTEGER REFERENCES metadata(id) ON DELETE CASCADE,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        hours FLOAT NOT NULL DEFAULT 0 CHECK (hours >= 0.0),
        has_photo BOOLEAN NOT NULL DEFAULT FALSE
      )
    SQL

    execute "CREATE INDEX people_user_hours ON people(user_id, hours)"
    execute "CREATE UNIQUE INDEX people_logbook_id ON people(user_id, logbook_id)"
  end

  def down
    drop_table :people
  end
end
