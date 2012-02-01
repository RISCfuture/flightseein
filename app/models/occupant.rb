# A link between a {Flight} and a {Person} who was either a crew member or
# passenger on that flight.
#
# Fields
# ------
#
# |        |                                                                                                |
# |:-------|:-----------------------------------------------------------------------------------------------|
# | `role` | The person's role as a crewmember, e.g., "Safety pilot". If `nil`, the person was a passenger. |
#
# Associations
# ------------
#
# |          |                                     |
# |:---------|:------------------------------------|
# | `flight` | The {Flight} the occupant was on.   |
# | `person` | The {Person} who was on the flight. |

class Occupant < ActiveRecord::Base
  belongs_to :person, inverse_of: :occupantships
  belongs_to :flight, inverse_of: :occupants

  validates :person,
            presence: true
  validates :flight,
            presence: true
  validates :role,
            length: { maximum: 126 },
            allow_blank: true

  attr_accessible :person, :flight, :role, as: :importer

  # Overrides the `role` attribute to default to "Passenger".

  def role
    read_attribute(:role).presence || "Passenger"
  end
end
