class CreateImports < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      CREATE TYPE state_type AS ENUM(
        'pending', 'starting', 'importing_aircraft', 'importing_airports',
        'importing_passengers', 'importing_flights', 'uploading_photos',
        'completed', 'failed'
      )
    SQL

    execute <<-SQL
      CREATE TABLE imports (
        id SERIAL PRIMARY KEY,
        metadata_id INTEGER REFERENCES metadata(id) ON DELETE CASCADE,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        state state_type NOT NULL DEFAULT 'pending'
      )
    SQL

    execute "CREATE INDEX imports_user ON imports(user_id, state)"
  end

  def down
    drop_table :imports
  end
end
