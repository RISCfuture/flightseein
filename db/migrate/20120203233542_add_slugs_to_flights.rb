class AddSlugsToFlights < ActiveRecord::Migration[4.2]
  def up
    execute "ALTER TYPE slugged_class RENAME TO _old_slugged_class"
    execute "CREATE TYPE slugged_class AS ENUM ('Person', 'Destination', 'Flight')"
    execute "ALTER TABLE slugs RENAME COLUMN sluggable_type TO _old_sluggable_type"
    execute "ALTER TABLE slugs ADD COLUMN sluggable_type slugged_class"
    execute "UPDATE slugs SET sluggable_type = _old_sluggable_type::text::slugged_class"
    execute "ALTER TABLE slugs DROP COLUMN _old_sluggable_type"
    execute "DROP TYPE _old_slugged_class"
  end

  def down
    execute "ALTER TYPE slugged_class RENAME TO _old_slugged_class"
    execute "CREATE TYPE slugged_class AS ENUM ('Person', 'Destination')"
    execute "ALTER TABLE slugs RENAME COLUMN sluggable_type TO _old_sluggable_type"
    execute "ALTER TABLE slugs ADD COLUMN sluggable_type slugged_class"
    execute "UPDATE slugs SET sluggable_type = _old_sluggable_type::text::slugged_class"
    execute "ALTER TABLE slugs DROP COLUMN _old_sluggable_type"
    execute "DROP TYPE _old_slugged_class"
  end
end
