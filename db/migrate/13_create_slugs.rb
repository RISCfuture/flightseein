class CreateSlugs < ActiveRecord::Migration[4.2]
  def up
    execute "CREATE TYPE slugged_class AS ENUM('Person', 'Destination')"
    execute <<-SQL
      CREATE TABLE slugs (
        id SERIAL PRIMARY KEY,
        sluggable_type slugged_class NOT NULL,
        sluggable_id INTEGER NOT NULL,
        active BOOLEAN NOT NULL DEFAULT TRUE,
        slug CHARACTER VARYING(126) NOT NULL CHECK (CHAR_LENGTH(slug) > 0),
        scope CHARACTER VARYING(126),
        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
      )
    SQL

    execute "CREATE INDEX slugs_for_record ON slugs(sluggable_type, sluggable_id, active)"
    execute "CREATE UNIQUE INDEX slugs_unique ON slugs(sluggable_type, scope, slug)"
  end

  def down
    drop_table :slugs
  end
end
