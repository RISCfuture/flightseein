# A person present on a {Flight}. It could be either the pilot-in-command or a
# passenger. A person record is exclusive to a {User} account.
#
# Fields
# ------
#
# |                 |                                                                                                              |
# |:----------------|:-------------------------------------------------------------------------------------------------------------|
# | `hours`         | _(cached counter)_ The total number of hours this person has logged as pilot or passenger.                   |
# | `logbook_id`    | The unique ID assigned to this person by the user's logbook; used for matching passengers in future imports. |
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
#
# Associations
# ------------
#
# |                   |                                                               |
# |:------------------|:--------------------------------------------------------------|
# | `user`            | The {User} who imported this person.                          |
# | `command_flights` | The {Flight Flights} this person commanded.                   |
# | `sic_flights`     | The {Flight Flights} this person was second-in-command for.   |
# | `flights`         | The {Flight Flights} this person was a passenger or pilot on. |

class Person < ActiveRecord::Base
  include HasMetadata
  include Slugalicious

  slugged :name, scope: ->(person) { person.user.subdomain }, slugifier: ->(str) { str.remove_formatting.replace_whitespace('_').collapse('_') }

  belongs_to :user, inverse_of: :people
  has_many :command_flights, class_name: 'Flight', foreign_key: 'pic_id', dependent: :restrict, inverse_of: :pic
  has_many :sic_flights, class_name: 'Flight', foreign_key: 'sic_id', dependent: :restrict, inverse_of: :sic
  has_and_belongs_to_many :flights, uniq: true

  has_metadata(
    name: { presence: true, length: { maximum: 100 } },
    notes: { length: { maximum: 1000 }, allow_blank: true },

    photo_file_name: { allow_blank: true },
    photo_content_type: { allow_blank: true, format: { with: /^image\// } },
    photo_file_size: { type: Fixnum, allow_blank: true, numericality: { less_than: 2.megabytes } },
    photo_updated_at: { type: Time, allow_blank: true }
  )

  validates :user,
            presence: true
  validates :hours,
            presence: true,
            numericality: { greater_than_or_equal_to: 0.0 }
  validates :logbook_id,
            presence: true,
            numericality: { only_integer: true },
            uniqueness: { scope: :user_id }

  attr_accessible :name, :photo

  has_attached_file :photo,
                    processors: [ :round_corners ],
                    styles: {
                      profile:  '200x200>',
                      logbook:  '32x32#',
                      stat:     '64x64#',
                      carousel: { geometry: '140x100#', format: :png, border_radius: 8 }
                    },
                    default_url: "person/:style-missing.png"

  scope :randomly, order('RANDOM()')

  # Updates this person's `hours` field from their flights, and saves the
  # record.

  def update_hours!
    update_attribute :hours, flights.sum(:duration)
  end

  # @private
  def to_param
    slug = slugs.loaded? ? slugs.detect(&:active) : slugs.active.first
    slug.try(:slug)
  end
end
