class AddAdminToUsers < ActiveRecord::Migration[4.2]
  def up
    execute "ALTER TABLE users ADD COLUMN admin BOOLEAN NOT NULL DEFAULT FALSE"
  end

  def down
    execute "ALTER TABLE users DROP COLUMN admin"
  end
end
