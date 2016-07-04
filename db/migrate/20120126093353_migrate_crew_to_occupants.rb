class MigrateCrewToOccupants < ActiveRecord::Migration[4.2]
  Flight.belongs_to :pic, class_name: 'Person'
  Flight.belongs_to :sic, class_name: 'Person'
  Flight.has_and_belongs_to_many :passengers, class_name: 'Person', join_table: 'flights_passengers'

  def up
    Flight.find_each do |flight|
      flight.occupants.create!(person: flight.pic, role: "Pilot in command") if flight.pic
      flight.occupants.create!(person: flight.sic, role: "Second in command") if flight.sic
      flight.passengers.each { |pax| flight.occupants.create!(person: pax) }
    end
  end

  def down
    Occupant.includes(:flight).find_each do |occupant|
      occupant.flight.pic_id = occupant.person_id if occupant.role == "Pilot in command"
      occupant.flight.sic_id = occupant.person_id if occupant.role == "Second in command"
      occupant.flight.passengers << occupant.person if occupant.role.nil?
    end
  end
end
