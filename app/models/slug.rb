# Stores slugs used to prettify URLs. For more information, see the
# `Slugalicious` mixin.
#
# As new slugs are created, old ones are marked as inactive and kept around for
# redirect purposes. Once a slug is old enough, it is deleted and its value can
# be used for new records (no longer redirects).
#
# Associations
# ------------
#
# |             |                                       |
# |:------------|:--------------------------------------|
# | `sluggable` | The record that this slug references. |
#
# Properties
# ----------
#
# |          |                                                                                                  |
# |:---------|:-------------------------------------------------------------------------------------------------|
# | `slug`   | The slug, lowercased and normalized. Slugs must be unique to their @sluggable_type@ and @scope@. |
# | `active` | Whether this is the most recently generated slug for the sluggable.                              |
# | `scope`  | Freeform data scoping this slug to a certain subset of records within the model.                 |

class Slug < ApplicationRecord
  belongs_to :sluggable, polymorphic: true

  scope :for, ->(object_or_type, object_id=nil) {
    object_type = object_id ? object_or_type : object_or_type.class.to_s
    object_id   ||= object_or_type.id
    where(sluggable_type: object_type, sluggable_id: object_id)
  }
  scope :for_class, ->(model) { where(sluggable_type: model.to_s) }
  scope :from_slug, ->(klass, scope, slug) {
    where(sluggable_type: klass.to_s, slug: slug, scope: scope)
  }
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  validates :slug,
            presence:   true,
            length:     { maximum: 126 },
            uniqueness: { case_sensitive: false, scope: [:scope, :sluggable_type] } #TODO validate scope case-insensitively
  validates :scope,
            length:      { maximum: 126 },
            allow_blank: true
  validate :one_active_slug_per_object

  # Marks a slug as active and deactivates all other slugs assigned to the
  # record.

  def activate!
    self.class.transaction do
      Slug.for(sluggable_type, sluggable_id).update_all(active: false)
      update_attribute :active, true
    end
  end

  private

  def one_active_slug_per_object
    return unless new_record? or (active? and active_changed?)
    errors.add(:active, :one_per_sluggable) if active? and Slug.active.for(sluggable_type, sluggable_id).count > 0
  end
end
