class AirportsController < ApplicationController
  respond_to :html
  before_filter :find_airport, only: :show

  # HTML
  # ====
  #
  # Displays a page that dynamically loads a list of {Destination Destinations}.
  #
  # JSON
  # ====
  #
  # Returns information about destinations in 50-long pages; used by the HTML
  # view. Airports are returned in arbitrary order.
  #
  # Parameters
  # ----------
  #
  # |               |                                                              |
  # |:--------------|:-------------------------------------------------------------|
  # | `last_record` | The ID of a record to load rows after (used for pagination). |
  #
  # Routes
  # ======
  #
  # * `GET /airports`

  def index
    respond_to do |format|
      format.html do
        airport = subdomain_owner.destinations.first.try(:airport)
        if airport then
          @lat, @lon = airport.lat, airport.lon
        else
          @lat, @lon = 38.0, -122.0
        end
        # index.html.erb
      end

      format.json do
        destinations = subdomain_owner.destinations.
          includes(:metadata, airport: :metadata).
          order('airport_id ASC').
          limit(50)

        if params['last_record'] then
          destinations = destinations.where('airport_id > ?', params['last_record'])
        end

        render(json: build_json(destinations).to_json)
      end
    end
  end

  # Displays information about a {Destination}.
  #
  # Routes
  # ------
  #
  # * `GET /airports/[id]`
  #
  # Path Parameters
  # ---------------
  #
  # |      |                                                       |
  # |:-----|:------------------------------------------------------|
  # | `id` | The {Airport#identifier identifier} of the {Airport}. |

  def show
    if @destination.notes.present? then
      @notes = Redcarpet.new(@destination.notes)
      @notes.smart = true
      @notes.no_image = true
      @notes.safelink = true
      @notes.autolink = true
    end
    
    respond_with @destination
  end

  private

  def build_json(destinations)
    destinations.map do |dest|
      {
        airport_id: dest.airport_id,
        photo: view_context.image_path(dest.photo.url(:stat)),
        url: airport_url(dest.airport),
        airport: {
          name: dest.airport.name,
          city: dest.airport.city,
          state: dest.airport.state,
          identifier: dest.airport.identifier,
          lat: dest.airport.lat,
          lon: dest.airport.lon
        }
      }
    end
  end

  def find_airport
    @airport = Airport.with_ident(params[:id]).first || raise(ActiveRecord::RecordNotFound)
    @destination = subdomain_owner.destinations.find_by_airport_id(@airport.id) || raise(ActiveRecord::RecordNotFound)
  end
end
