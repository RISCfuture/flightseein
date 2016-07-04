class AddMeBooleanToPeople < ActiveRecord::Migration[4.2]
  def change
    change_table :people, bulk: true do |t|
      t.boolean :me, null: false, default: false
      t.remove_index :name => 'people_user_hours'
      t.index [ :user_id, :me, :hours ], name: 'people_user_me_hours'
    end
  end
end
