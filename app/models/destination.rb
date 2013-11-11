# An {Airport} flown to by a {User}. While `Airport`s are loaded from the FAA
# FADDS database, `Destination`s include information specific to a user: a
# photo, notes, etc. added by a user.
#
# Fields
# ------
#
# |                 |                                                                                                          |
# |:----------------|:---------------------------------------------------------------------------------------------------------|
# | `flights_count` | _(cached counter)_ The number of {Flight Flights} where this airport is an origin, destination, or stop. |
#
# Metadata
# --------
#
# |                      |                                                          |
# |:---------------------|:---------------------------------------------------------|
# | `notes`              | Additional notes added by the user (Markdown formatted). |
# | `photo_file_name`    | Used by Paperclip.                                       |
# | `photo_content_type` | Used by Paperclip.                                       |
# | `photo_file_size`    | Used by Paperclip.                                       |
# | `photo_updated_at`   | Used by Paperclip.                                       |
# | `photo_fingerprint`  | Used by Paperclip.                                       |
#
# Associations
# ------------
#
# |           |                                               |
# |:----------|:----------------------------------------------|
# | `user`    | The {User} who imported this destination.     |
# | `airport` | The {Airport} referenced by this destination. |

class Destination < ActiveRecord::Base
  include HasMetadata
  include CheckForDuplicateAttachedFile

  self.primary_key = 'airport_id'

  belongs_to :user, inverse_of: :destinations
  belongs_to :airport, inverse_of: :destinations

  has_metadata(
      notes:              { length: { maximum: 1000 }, allow_blank: true },

      photo_file_name:    { allow_blank: true },
      photo_content_type: { allow_blank: true, format: { with: /\Aimage\// } },
      photo_file_size:    { type: Fixnum, allow_blank: true, numericality: { less_than: 2.megabytes } },
      photo_updated_at:   { type: Time, allow_blank: true },
      photo_fingerprint:  { allow_blank: true }
  )

  validates :user,
            presence: true
  validates :airport,
            presence: true

  attr_readonly :airport

  has_attached_file :photo, Carousel.paperclip_options(
      styles:      {
          profile: '200x200>',
          logbook: '32x32#',
          stat:    '64x64#',
      },
      default_url: "airport/:style-missing.png")
  check_for_duplicate_attached_file :photo

  scope :randomly, -> { order('RANDOM()') }

  # Recalculates the `flights_count` attribute.

  def update_flights_count!
    update_attribute :flights_count,
                     user.flights.where(origin_id: id).count +
                         user.flights.where(destination_id: id).count +
                         Stop.where(destination_id: id).count
  end
end
