class AddCarouselIndexes < ActiveRecord::Migration[4.2]
  def change
    change_table :people do |t|
      t.index [ :user_id, :has_photo, :me, :hours ], name: 'people_user_photo_me_hours'
    end

    change_table :destinations do |t|
      t.index [ :user_id, :has_photo ], name: 'dest_user_photo'
    end
  end
end
