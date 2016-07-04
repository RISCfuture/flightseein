class ConvertLogbookIdToUuid < ActiveRecord::Migration[4.2]
  def up
    execute "ALTER TABLE flights ALTER COLUMN logbook_id TYPE CHARACTER VARYING(60)"
    execute "ALTER TABLE people ALTER COLUMN logbook_id TYPE CHARACTER VARYING(60)"
  end

  def down
    execute "ALTER TABLE flights ALTER COLUMN logbook_id TYPE INTEGER"
    execute "ALTER TABLE people ALTER COLUMN logbook_id TYPE INTEGER"
  end
end
