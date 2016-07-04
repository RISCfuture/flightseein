class CreateMetadata < ActiveRecord::Migration[4.2]
  def change
    create_table :metadata do |t|
      t.text :data, null: false
    end
  end
end
