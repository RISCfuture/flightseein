# A photograph taken while on a {Flight}. These photos are displayed alongside
# the flight's blog entry.
#
# Metadata
# --------
#
# |                      |                                   |
# |:---------------------|:----------------------------------|
# | `caption`            | A short description of the photo. |
# | `image_file_name`    | Used by Paperclip.                |
# | `image_content_type` | Used by Paperclip.                |
# | `image_file_size`    | Used by Paperclip.                |
# | `image_updated_at`   | Used by Paperclip.                |
# | `image_fingerprint`  | Used by Paperclip.                |
#
# Associations
# ------------
#
# |          |                                       |
# |:---------|:--------------------------------------|
# | `flight` | The {Flight} this photo was taken on. |


class Photograph < ActiveRecord::Base
  include HasMetadata

  belongs_to :flight, inverse_of: :photographs

  has_metadata(
    caption:            { allow_blank: true, length: { maximum: 300 } },
    image_file_name:    { presence: true },
    image_content_type: { presence: true, format: { with: /^image\// } },
    image_file_size:    { type: Fixnum, presence: true, numericality: { less_than: 2.megabytes } },
    image_updated_at:   { type: Time, presence: true },
    image_fingerprint:  { presence: true }
  )

  validates :flight,
            presence: true

  after_save { |obj| obj.flight.update_attribute :has_photos, true }

  attr_accessible :image, :caption, as: :pilot
  attr_readonly :image

  has_attached_file :image, Carousel.paperclip_options(
    styles: {
              blog:    '200x200>',
              logbook: '32x32#',
            })
end
