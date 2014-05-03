# An airport that {Flight flights} can originate or terminate at. Airports are
# not linked to a {User} account, and cannot be edited by users (see
# {Destination}). Their information is imported from a NFDC FADDS distribution
# (see {AirportImporter}).
#
# Fields
# ------
#
# |               |                                                                                     |
# |:--------------|:------------------------------------------------------------------------------------|
# | `site_number` | The identifier used by the FAA for this airport's record in the FADDS database.     |
# | `lid`         | The FAA location identifier, a three- or four-letter code identifying this airport. |
# | `icao`        | The ICAO's four-letter identifier for this airport.                                 |
# | `iata`        | The IATA's three- or four-letter identifier for this airport.                       |
#
# Metadata
# --------
#
# |         |                                                              |
# |:--------|:-------------------------------------------------------------|
# | `name`  | The airport's full name.                                     |
# | `city`  | The name of the city that the airport serves.                |
# | `state` | The two-letter USPS code for the state containing the city.  |
# | `lat`   | The airport's latitude, in decimal degrees (north positive). |
# | `lon`   | The airport's longitude, in decimal degrees (east positive). |
#
# Associations
# ------------
#
# |                |                                                          |
# |:---------------|:---------------------------------------------------------|
# | `destinations` | The {Destination Destinations} referencing this airport. |

class Airport < ActiveRecord::Base
  include HasMetadataColumn

  STATES = %w( AL AK AS AZ AR CA CO CT DE DC FM FL GA GU HI ID IL IN IA KS KY LA
               ME MH MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND MP OH OK OR PW
               PA PR RI SC SD TN TX UT VT VI VA WA WV WI WY )

  has_many :destinations, dependent: :restrict_with_exception, inverse_of: :airport

  has_metadata_column(
      name:  {
          presence: true,
          length:   { maximum: 100 } },
      city:  {
          length:      { maximum: 100 },
          allow_blank: true },
      state: {
          inclusion:   { in: STATES },
          allow_blank: true },
      lat:   {
          type:         Float,
          numericality: { :>= => -90, :<= => 90 },
          allow_nil:    true },
      lon:   {
          numericality: { :>= => -180, :<= => 180 },
          allow_nil:    true
      }
  )

  validates :site_number,
            presence:   true,
            uniqueness: true,
            length:     { maximum: 11 }
  validates :lid,
            length:      { within: 3..4 },
            format:      { with: /\A[A-Z0-9]+\z/ },
            presence:    { if: ->(airport) { airport.icao.blank? and airport.iata.blank? } },
            allow_blank: true
  validates :icao,
            length:      { is: 4 },
            format:      { with: /\A[A-Z0-9]+\z/ },
            presence:    { if: ->(airport) { airport.lid.blank? and airport.iata.blank? } },
            allow_blank: true
  validates :iata,
            length:      { within: 3..4 },
            format:      { with: /\A[A-Z0-9]+\z/ },
            uniqueness:  { scope: [:lid, :icao] },
            presence:    { if: ->(airport) { airport.icao.blank? and airport.lid.blank? } },
            allow_blank: true

  attr_readonly :site_number

  scope :with_ident, ->(lid, iata=nil, icao=nil) {
    iata    ||= lid
    icao    ||= iata
    clauses = []
    clauses << 'lid = ?' if lid.present?
    clauses << 'iata = ?' if iata.present?
    clauses << 'icao = ?' if icao.present?
    where(clauses.join(' OR '), *[lid, iata, icao].select(&:present?))
  }

  # @return [String] The airport's LID, ICAO code, or IATA code.

  def identifier
    lid || icao || iata
  end

  # @private
  def to_param() identifier end
end
