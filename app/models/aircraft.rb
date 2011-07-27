# An airplane, identified by its tail number. An aircraft record belongs to a
# {User} accounts; multiple users could have separate `Aircraft` with the same
# tail number.
#
# Fields
# ------
#
# |         |                             |
# |:--------|:----------------------------|
# | `ident` | The aircraft's tail number. |
#
# Metadata
# --------
#
# |                      |                                                                      |
# |:---------------------|:---------------------------------------------------------------------|
# | `year`               | The year this aircraft was built.                                    |
# | `type`               | The FAA type code for this aircraft (e.g., "C172" for a Cessna 172). |
# | `long_type`          | A human description of the aircraft type (e.g., "Cessna 172").       |
# | `notes`              | {User}-supplied notes about the aircraft.                            |
# | `image_file_name`    | Used by Paperclip.                                                   |
# | `image_content_type` | Used by Paperclip.                                                   |
# | `image_file_size`    | Used by Paperclip.                                                   |
# | `image_updated_at`   | Used by Paperclip.                                                   |
# | `image_fingerprint`  | Used by Paperclip.                                                   |
#
# Associations
# ------------
#
# |           |                                                 |
# |:----------|-------------------------------------------------|
# | `flights` | The {Flight flights} this aircraft has been on. |

class Aircraft < ActiveRecord::Base
  include HasMetadata
  include CheckForDuplicateAttachedFile

  belongs_to :user, inverse_of: :aircraft
  has_many :flights, inverse_of: :aircraft, dependent: :restrict

  has_metadata(
    year: {
      type: Fixnum,
      inclusion: { in: 1903..2100 },
      allow_blank: true },
    type: {
      length: { maximum: 10 },
      format: { with: /^[A-Z0-9\- ]+$/ },
      allow_blank: true },
    long_type: {
      length: { maximum: 100 },
      allow_blank: true },
    notes: {
      length: { maximum: 500 },
      allow_blank: true },

  image_file_name: { allow_blank: true },
    image_content_type: { allow_blank: true, format: { with: /^image\// } },
    image_file_size: { type: Fixnum, allow_blank: true, numericality: { less_than: 2.megabytes } },
    image_updated_at: { type: Time, allow_blank: true },
    image_fingerprint: { allow_blank: true }
  )

  validates :ident,
            presence: true,
            format: { with: /^[A-Z0-9]+$/ },
            uniqueness: { scope: :user_id }

  before_validation(on: :create) do |aircraft|
    aircraft.ident = aircraft.ident.upcase if aircraft.ident
  end

  attr_accessible :ident, :year, :type, :long_type, :notes, :image
  attr_readonly :ident

  has_attached_file :image,
                    styles: { stat: '64x64#' },
                    default_url: "aircraft/:style-missing.png"
  check_for_duplicate_attached_file :image
end
