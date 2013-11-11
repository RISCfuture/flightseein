# An enroute stop at a {Destination} while on a {Flight}. Destinations are
# ordered by their sequence number.
#
# Fields
# ------
#
# |            |                                               |
# |:-----------|:----------------------------------------------|
# | `sequence` | The stop number on the flight, starting at 1. |
#
# Associations
# ------------
#
# |               |                                        |
# |:--------------|:---------------------------------------|
# | `flight`      | The {Flight} the stop was made during. |
# | `destination` | The {Destination} the stop was at.     |

class Stop < ActiveRecord::Base
  belongs_to :flight, inverse_of: :stops

  # @private
  def destination() flight.user.destinations.where(airport_id: destination_id).first end
  # @private
  def destination=(dest) self.destination_id = dest.airport_id end

  validates :flight,
            presence: true
  validates :destination_id,
            presence: true
  validates :sequence,
            presence:     true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1 }
end
