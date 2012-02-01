class RemoveLogbookIdFromDestinations < ActiveRecord::Migration
  def up
    execute "ALTER TABLE destinations DROP logbook_id"
  end

  def down
    execute "ALTER TABLE destinations ADD logbook_id INTEGER NOT NULL"
    execute "CREATE UNIQUE INDEX destinations_logbook_id ON destinations(user_id, logbook_id)"
  end
end
