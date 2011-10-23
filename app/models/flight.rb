# An instance of one or more {Person people} taking an {Aircraft} on a flight
# from one {Airport} to another. A flight is exclusive to a {User} account.
#
# Flights have a `sequence` column that sequences flights in order by date.
# Two flights occurring on the same day have an arbitrary but consistent
# ordering. Flights are unsequenced when first created; you must call the
# {User#update_flight_sequence!} method to sequence a user's flights.
#
# Fields
# ------
#
# |              |                                                                                                           |
# |:-------------|:----------------------------------------------------------------------------------------------------------|
# | `duration`   | The length of the flight, in hours.                                                                       |
# | `logbook_id` | The unique ID assigned to this person by the user's logbook; used for matching flights in future imports. |
# | `has_blog`   | `true` if a blog entry has been written for this flight.                                                  |
# | `has_photos` | `true` if the flight has at least one {Photograph}.                                                       |
# | `sequence`   | A number ordering the flights: 1 is the first of a user's flights, and so on from there.                  |
#
# Metadata
# --------
#
# |           |                                                            |
# |:----------|:-----------------------------------------------------------|
# | `remarks` | The pilot's notes about what transpired during the flight. |
# | `blog`    | Markdown-formatted blog entry about the flight.            |
#
# Associations
# ------------
#
# |              |                                                                    |
# |:-------------|:-------------------------------------------------------------------|
# | `user`       | The {User} account owning the flight.                              |
# | `pic`        | The {Person} who was primarily pilot-in-command during the flight. |
# | `sic`        | The {Person} who was the second-in-command during the flight.      |
# | `aircraft`   | The {Aircraft} the flight was taken in.                            |
# | `passengers` | The {Person passengers} on board the flight.                       |
# | `people`     | All {Person people} present on the flight (PIC and SIC included).  |

class Flight < ActiveRecord::Base
  extend ActiveSupport::Memoizable
  include HasMetadata
  
  belongs_to :user, inverse_of: :flights
  belongs_to :pic, class_name: 'Person', foreign_key: 'pic_id', inverse_of: :command_flights
  belongs_to :sic, class_name: 'Person', foreign_key: 'sic_id', inverse_of: :sic_flights
  belongs_to :aircraft, inverse_of: :flights
  has_many :photographs, inverse_of: :flight, dependent: :delete_all
  has_many :stops, inverse_of: :flight, dependent: :delete_all
  has_and_belongs_to_many :people, uniq: true
  has_and_belongs_to_many :passengers, uniq: true, join_table: 'flights_passengers', class_name: 'Person'

  has_metadata(
    remarks: { length: { maximum: 500 }, allow_blank: true },
    blog: { allow_blank: true }
  )

  validates :user,
            presence: true
  validates :aircraft,
            presence: true
  validates :duration,
            presence: true,
            numericality: { greater_than: 0.0 }
  validates :logbook_id,
            presence: true,
            numericality: { only_integer: true },
            uniqueness: { scope: :user_id }
  validates :date,
            presence: true
  validates :origin_id,
            presence: true
  validates :destination_id,
            presence: true
  validates :sequence,
            numericality: { only_integer: true, greater_than_or_equal_to: 1 },
            uniqueness: { scope: :user_id },
            allow_blank: true

  before_save { |obj| obj.has_blog = obj.blog.present?; true }
  after_save :update_people!, if: ->(obj) { obj.pic_id_changed? or obj.sic_id_changed? }

  attr_accessible :origin, :destination, :pic, :sic, :aircraft, :people,
                  :remarks, :duration, :date, as: :importer
  attr_accessible :blog, :photographs_attributes, as: :pilot

  accepts_nested_attributes_for :photographs, allow_destroy: true, reject_if: ->(attrs) { attrs['image'].nil? and attrs['id'].nil? }

  # @private
  def origin() user.destinations.where(airport_id: origin_id).first end
  # @private
  def destination() user.destinations.where(airport_id: destination_id).first end
  # @private
  def origin=(dest) self.origin_id = dest.try(:airport_id) end
  # @private
  def destination=(dest) self.destination_id = dest.try(:airport_id) end

  # @return [Array<Destination>] The origin, destination, and all intermediate
  #   stops, ordered in sequence.

  def destinations
    ids = [ origin_id, stops.order('sequence ASC').map(&:destination_id), destination_id ].flatten.compact
    scope = user.destinations.where(airport_id: ids)
    scope = yield(scope) if block_given?
    dests = scope.all
    ids.map { |id| dests.detect { |dest| dest.airport_id == id } }
  end

  # @return [Flight, nil] The user's previous flight, or `nil` if this is the
  #   first flight or an as-yet unsequenced flight.

  def previous
    return nil unless sequence
    user.flights.where(sequence: sequence - 1).first
  end
  memoize :previous

  # @return [Flight, nil] The user's next flight, or `nil` if this is the latest
  #   flight or an as-yet unsequenced flight.

  def next
    return nil unless sequence
    user.flights.where(sequence: sequence + 1).first
  end
  memoize :next

  # Ensures that the PIC, SIC, and all passengers are included in the `people`
  # association.

  def update_people!
    self.people = [ pic, sic, *passengers ].compact.uniq_by(&:id)
  end
end
