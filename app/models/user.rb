require 'digest/sha1'

# An account on this website. A user imports their logbook, from which {Flight}
# and {Person} records are created. These records are exclusive to this user
# account. The associated {Aircraft} and {Airport} records are shared among
# different users.
#
# Each user gets a unique subdomain, under which they can browse all their
# flights and passengers. Though user records are paranoid, the subdomain is
# relinquished if the user is deactivated. This is done by resetting the
# subdomain to a random string, and storing the old subdomain.
#
# Users log in with, and are uniquely identified by, their email addresses. A
# user's password is stored SHA1-encrypted with a global and a per-record salt.
#
# Fields
# ------
#
# |             |                                                                                |
# |:------------|:-------------------------------------------------------------------------------|
# | `email`     | The user's email address and their login identifier.                           |
# | `subdomain` | The user's subdomain.                                                          |
# | `active`    | Whether or not the user account is active. Inactive accounts are inaccessible. |
#
# Metadata
# --------
#
# |                       |                                                                         |
# |:----------------------|:------------------------------------------------------------------------|
# | `encrypted_password`  | The user's password, SHA1-encrypted.                                    |
# | `salt`                | A per-record salt used when encrypting the password.                    |
# | `name`                | The user's full name.                                                   |
# | `quote`               | A favorite quote to display on the user's account page.                 |
# | `hours`               | Total number of flight hours for this user.                             |
# | `certificate`         | The certificate level of this user (e.g., "private").                   |
# | `has_instrument`      | Whether this user has an instrument rating.                             |
# | `certification_date`  | The date this user received his certification.                          |
# | `old_subdomain`       | Stores the user's old subdomain if the user relinquishes his subdomain. |
# | `avatar_file_name`    | Used by Paperclip.                                                      |
# | `avatar_content_type` | Used by Paperclip.                                                      |
# | `avatar_file_size`    | Used by Paperclip.                                                      |
# | `avatar_updated_at`   | Used by Paperclip.                                                      |
# | `avatar_fingerprint`  | Used by Paperclip.                                                      |
#
# Associations
# ------------
#
# |           |                                              |
# |:----------|:---------------------------------------------|
# | `flights` | The {Flight Flights} this user has imported. |
# | `people`  | The {Person People} this user has imported.  |

class User < ActiveRecord::Base
  include HasMetadata
  
  attr_accessor :password

  has_many :aircraft, dependent: :delete_all, inverse_of: :user
  has_many :destinations, dependent: :delete_all, inverse_of: :user
  has_many :flights, dependent: :delete_all, inverse_of: :user
  has_many :imports, dependent: :delete_all, inverse_of: :user
  has_many :people, dependent: :delete_all, inverse_of: :user

  has_metadata(
    encrypted_password: { presence: true },
    salt: { presence: true },

    name: { length: { maximum: 100 }, allow_blank: true },
    quote: { length: { maximum: 500 }, allow_blank: true },
    hours: { type: Float, default: 0.0, numericality: { greater_than_or_equal_to: 0 } },
    certificate: { allow_blank: true },
    has_instrument: { type: Boolean, default: false },
    certification_date: { type: Date, allow_blank: true },

    old_subdomain: { allow_blank: true },

    avatar_file_name: { allow_blank: true },
    avatar_content_type: { allow_blank: true, format: { with: /^image\// } },
    avatar_file_size: { type: Fixnum, allow_blank: true, numericality: { less_than: 2.megabytes } },
    avatar_updated_at: { type: Time, allow_blank: true },
    avatar_fingerprint: { allow_blank: true }
  )

  validates :email,
            presence: true,
            email: true,
            uniqueness: true
  validates :subdomain,
            presence: true,
            format: { with: /^[a-z0-9][a-z0-9_\-][a-z0-9]+$/ },
            length: { minimum: 2, maximum: 32 },
            uniqueness: true

  before_validation :set_salt, on: :create
  before_validation(on: :create) { |u| u.email = u.email.downcase if u.email }
  before_validation(on: :create) { |u| u.subdomain = u.subdomain.downcase if u.subdomain }
  before_validation :encrypt_password, if: ->(obj) { obj.password.present? }
  before_update :relinquish_subdomain, if: ->(u) { u.active_changed? and not u.active? }
  after_save :update_cache
  after_destroy :invalidate_cache

  attr_accessible :email, :password, :name, :quote, :subdomain, :avatar
  attr_readonly :email

  scope :active, where(active: true)
  scope :with_email, ->(email) { where(email: email.try(:downcase)) }
  scope :for_subdomain, ->(subdomain) { where(subdomain: subdomain.try(:downcase)) }

  has_attached_file :avatar,
                    styles: { profile: '200x200>', profile_small: '100x100>' },
                    default_url: "user/:style-missing.png"

  # Determines if a provided password matches the password stored for a user.
  #
  # @param [User] user A user to authenticate.
  # @param [String] password A proposed password.
  # @return [true, false] Whether or not the password was correct.

  def self.authenticated?(user, password)
    return false unless user and password
    user.authenticated? password
  end

  # Determines if a provided password matches this user's password.
  #
  # @param [String] password A proposed password.
  # @return [true, false] Whether or not the password was correct.

  def authenticated?(password)
    encrypted_password == self.class.encrypt(password, salt)
  end

  # @return [String] The user's name, or if that is unavailable, the account
  #   portion of their email address.

  def best_name
    name.present? ? name : email.split('@').first
  end

  # @private
  def subdomain_cache_key
    self.class.subdomain_cache_key subdomain
  end

  # @private
  def self.subdomain_cache_key(subdomain)
    "User/#{subdomain}"
  end

  # Recalculates the `hours` metadata attribute by summing up the durations of
  # all {Flight Flights}.
  
  def update_hours!
    update_attribute :hours, flights.sum(:duration)
  end

  # Goes through all of a user's flights and updates their `sequence` fields.

  def update_flight_sequence!
    flights.update_all(sequence: nil)
    Flight.connection.execute <<-SQL
      UPDATE flights
      SET sequence = counter.num
      FROM (
        SELECT
          id,
          RANK() OVER (PARTITION BY user_id ORDER BY date ASC, id ASC) AS num
        FROM flights
        WHERE user_id = #{Flight.connection.quote id}) AS counter
      WHERE flights.id = counter.id;
    SQL
  end

  # The same as {#update_flight_sequence!}, but does so for every user in the
  # database.

  def self.update_all_flight_sequences!
    Flight.connection.execute <<-SQL
      UPDATE flights
      SET sequence = counter.num
      FROM (
        SELECT
          id,
          RANK() OVER (PARTITION BY user_id ORDER BY date ASC, id ASC) AS num
        FROM flights) AS counter
      WHERE flights.id = counter.id;
    SQL
  end

  def marshal_dump
    encode_with(hsh = Hash.new)
    hsh
  end

  def marshal_load(hsh)
    init_with hsh
  end

  private

  def set_salt
    self.salt ||= SecureRandom.base64(16)
  end

  def encrypt_password
    self.encrypted_password = self.class.encrypt(password, salt)
  end

  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("ab50a7#{password}1d9736346#{salt}edcb802")
  end

  def relinquish_subdomain
    self.old_subdomain = subdomain
    self.subdomain = SecureRandom.urlsafe_base64(24)[0, 32]
  end

  def update_cache
    Rails.cache.delete(self.class.subdomain_cache_key(subdomain_was)) if subdomain_changed?
    Rails.cache.write(subdomain_cache_key, self) if active?
  end

  def invalidate_cache
    Rails.cache.delete subdomain_cache_key
  end
end
