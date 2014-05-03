# A person present on a {Flight}. It could be either the pilot-in-command or a
# passenger. A person record is exclusive to a {User} account.
#
# Fields
# ------
#
# |              |                                                                                                              |
# |:-------------|:-------------------------------------------------------------------------------------------------------------|
# | `hours`      | _(cached counter)_ The total number of hours this person has logged as pilot or passenger.                   |
# | `logbook_id` | The unique ID assigned to this person by the user's logbook; used for matching passengers in future imports. |
# | `me`         | Id `true`, this is the `Person` record for the associated {User}.                                            |
#
# Metadata
# --------
#
# |                      |                                                             |
# |:---------------------|:------------------------------------------------------------|
# | `name`               | The person's first and last name.                           |
# | `notes`              | {User}-written notes about the person (Markdown-formatted). |
# | `photo_file_name`    | Used by Paperclip.                                          |
# | `photo_content_type` | Used by Paperclip.                                          |
# | `photo_file_size`    | Used by Paperclip.                                          |
# | `photo_updated_at`   | Used by Paperclip.                                          |
# | `photo_fingerprint`  | Used by Paperclip.                                          |
#
# Associations
# ------------
#
# |                 |                                                                    |
# |:----------------|:-------------------------------------------------------------------|
# | `user`          | The {User} who imported this person.                               |
# | `occupantships` | The times this person acted as a {Crewmember} on a flight.         |
# | `flights`       | The {Flight Flights} this person was a passenger or crewmember on. |

class Person < ActiveRecord::Base
  include HasMetadata
  include Slugalicious
  include CheckForDuplicateAttachedFile

  slugged :name, scope: ->(person) { person.user.subdomain }, slugifier: ->(str) { str.remove_formatting.replace_whitespace('_').collapse('_') }

  belongs_to :user, inverse_of: :people
  has_many :occupantships, class_name: 'Occupant', inverse_of: :person, dependent: :restrict_with_exception
  has_many :flights, through: :occupantships

  has_metadata(
      name:               { presence: true, length: { maximum: 100 } },
      notes:              { length: { maximum: 1000 }, allow_blank: true },

      photo_file_name:    { allow_blank: true },
      photo_content_type: { allow_blank: true },
      photo_file_size:    { type: Fixnum, allow_blank: true, numericality: { less_than: 2.megabytes } },
      photo_updated_at:   { type: Time, allow_blank: true },
      photo_fingerprint:  { allow_blank: true }
  )

  validates :user,
            presence: true
  validates :hours,
            presence:     true,
            numericality: { greater_than_or_equal_to: 0.0 }
  validates :logbook_id,
            presence:   true,
            uniqueness: { scope: :user_id }

  has_attached_file :photo, Carousel.paperclip_options(
      styles:      {
          profile: '200x200>',
          logbook: '32x32#',
          stat:    '64x64#',
      },
      default_url: "person/:style-missing.png")
  check_for_duplicate_attached_file :photo
  do_not_validate_attachment_file_type :photo

  scope :randomly, -> { order('RANDOM()') }
  scope :participating, -> { where('hours > 0') }
  scope :not_me, -> { where(me: false) }

  # Updates this person's `hours` field from their flights, and saves the
  # record.

  def update_hours!
    update_attribute :hours, flights.sum(:duration)
  end

  # @private
  def to_param() slug end
end
