class CreateUsers < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        metadata_id INTEGER REFERENCES metadata(id) ON DELETE CASCADE,
        email CHARACTER VARYING(255) NOT NULL UNIQUE CHECK (CHAR_LENGTH(email) > 0),
        subdomain CHARACTER VARYING(32) NOT NULL UNIQUE CHECK (CHAR_LENGTH(subdomain) >= 2),
        active BOOLEAN NOT NULL DEFAULT TRUE,
        has_avatar BOOLEAN NOT NULL DEFAULT FALSE,
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      )
    SQL
  end

  def down
    drop_table :users
  end
end
