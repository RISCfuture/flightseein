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
# |             |                                                                        |
# |:------------|:-----------------------------------------------------------------------|
# | `user`      | The {User} account owning the flight.                                  |
# | `aircraft`  | The {Aircraft} the flight was taken in.                                |
# | `occupants` | All {Occupant Occupants} present on the flight (PIC and SIC included). |

class Flight < ActiveRecord::Base
  include HasMetadata
  include Slugalicious

  belongs_to :user, inverse_of: :flights
  belongs_to :aircraft, inverse_of: :flights
  has_many :photographs, inverse_of: :flight, dependent: :delete_all
  has_many :stops, inverse_of: :flight, dependent: :delete_all
  has_many :occupants, inverse_of: :flight, dependent: :delete_all

  slugged ->(flight) { "#{flight.date.strftime '%Y-%m-%d'} #{flight.destinations.map(&:airport).map(&:identifier).join('-')}" },
          scope:     ->(flight) { flight.user.subdomain },
          slugifier: ->(str) { str.remove_formatting.replace_whitespace('_').collapse('_') }

  has_metadata(
      remarks: { length: { maximum: 500 }, allow_blank: true },
      blog:    { allow_blank: true }
  )

  validates :user,
            presence: true
  validates :aircraft,
            presence: true
  validates :duration,
            presence:     true,
            numericality: { greater_than: 0.0 }
  validates :logbook_id,
            presence:   true,
            uniqueness: { scope: :user_id }
  validates :date,
            presence: true
  validates :origin_id,
            presence: true
  validates :destination_id,
            presence: true
  validates :sequence,
            numericality: { only_integer: true, greater_than_or_equal_to: 1 },
            uniqueness:   { scope: :user_id },
            allow_blank:  true

  before_save { |obj| obj.has_blog = obj.blog.present?; true }

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
    ids   = [origin_id, stops.order('sequence ASC').map(&:destination_id), destination_id].flatten.compact
    scope = user.destinations.where(airport_id: ids)
    scope = yield(scope) if block_given?
    dests = scope.to_a
    ids.map { |id| dests.detect { |dest| dest.airport_id == id } }
  end

  # @return [Flight, nil] The user's previous flight, or `nil` if this is the
  #   first flight or an as-yet unsequenced flight.

  def previous
    return nil unless sequence
    @previous ||= user.flights.where(sequence: sequence - 1).first
  end

  # @return [Flight, nil] The user's next flight, or `nil` if this is the latest
  #   flight or an as-yet unsequenced flight.

  def next
    return nil unless sequence
    @next ||= user.flights.where(sequence: sequence + 1).first
  end

  # @private
  def to_param() slug end
end
