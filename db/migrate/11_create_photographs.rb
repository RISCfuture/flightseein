class CreatePhotographs < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TABLE photographs (
        id SERIAL PRIMARY KEY,
        flight_id INTEGER NOT NULL REFERENCES flights(id) ON DELETE CASCADE,
        metadata_id INTEGER REFERENCES metadata(id) ON DELETE CASCADE
      )
    SQL

    execute "CREATE INDEX photographs_flight ON photographs(flight_id)"
  end

  def down
    drop_table :photographs
  end
end
