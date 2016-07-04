class AddSequenceToFlights < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      ALTER TABLE flights
        ADD sequence INTEGER CHECK (sequence >= 1)
    SQL

    change_table :flights, bulk: true do |t|
      t.remove_index :name => 'flights_user'
      t.remove_index :name => 'flights_user_dest'
      t.remove_index :name => 'flights_user_blog'
      t.remove_index :name => 'flights_with_photos'

      t.index [ :user_id, :sequence ], unique: true, name: 'flights_user'
      t.index [ :user_id, :destination_id, :sequence ], name: 'flights_user_dest'
      t.index [ :user_id, :has_blog, :sequence ], name: 'flights_user_blog'
    end
  end

  def down
    change_table :flights, bulk: true do |t|
      t.remove_index :name => 'flights_user'
      t.remove_index :name => 'flights_user_dest'
      t.remove_index :name => 'flights_user_blog'

      t.index [ :user_id, :date ], unique: true, name: 'flights_user'
      t.index [ :user_id, :destination_id, :date ], name: 'flights_user_dest'
      t.index [ :user_id, :has_blog, :date ], name: 'flights_user_blog'

      t.remove_index :name => 'flights_sequence'
      t.remove :sequence
    end
  end
end
