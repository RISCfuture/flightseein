# Controller for viewing a {User}'s {Flight Flights}.

class FlightsController < ApplicationController
  before_filter :find_flight, except: :index
  before_filter :owner_login_required, only: [ :edit, :update ]
  respond_to :html, :json

  # HTML
  # ====
  #
  # Displays a page that dynamically loads a list of flights and displays them
  # in a vaguely logbook-like format.
  #
  # |          |                                           |
  # |:---------|:------------------------------------------|
  # | `filter` | Passed to the JSON format of this action. |
  #
  # JSON
  # ====
  #
  # Returns information about flights in 50-long pages; used by the HTML view.
  # Flights are sorted by date descending.
  #
  # Parameters
  # ----------
  #
  # |               |                                                                                                       |
  # |:--------------|:------------------------------------------------------------------------------------------------------|
  # | `filter`      | If `all` (default), all flights are returned. If `blog`, only flights with blog entries are returned. |
  # | `last_record` | The ID of a record to load rows after (used for pagination).                                          |
  #
  # Routes
  # ======
  #
  # * `GET /flights`
  # * `GET /people/[person_id]/flights`
  # * `GET /airports/[airport_id]/flights`
  #
  # Path Parameters
  # ---------------
  #
  # |              |                                                                                                              |
  # |:-------------|:-------------------------------------------------------------------------------------------------------------|
  # | `person_id`  | The slug for a {Person}. Flights are limited to those in which that person was present.                      |
  # | `airport_id` | The {Airport#identifier identifier} for an {Airport}. Flights are limited to those arriving at that airport. |

  def index
    params['filter'] ||= 'all'

    respond_to do |format|
      format.html
      format.json do
        if params['person_id'] then
          person = Person.find_from_slug!(params['person_id'], request.subdomain)
          @flights = person.flights.includes(:slugs, occupants: { person: [ :metadata, :slugs ] })
        elsif params['airport_id'] then
          airport = Airport.with_ident(params['airport_id']).first || raise(ActiveRecord::RecordNotFound)
          destination = subdomain_owner.destinations.find_by_airport_id(airport.id) || raise(ActiveRecord::RecordNotFound)
          @flights = subdomain_owner.flights.includes(:slugs, occupants: { person: [ :metadata, :slugs ] }).where(destination_id: destination.id)
        else
          @flights = subdomain_owner.flights.includes(:slugs, occupants: { person: [ :metadata, :slugs ] })
        end

        @flights = @flights.
          includes(:metadata, aircraft: :metadata, photographs: :metadata, occupants: { person: [ :metadata, :slugs ] }).
          order('sequence DESC').
          limit(50)
        @flights = @flights.where(has_blog: true) if params['filter'] == 'blog'

        if params['last_record'] and params['last_record'].to_i > 0 then
          @flights = @flights.where('sequence < ?', params['last_record'].to_i)
        end

        render(json: build_json(@flights).to_json)
      end
    end
  end

  # Displays information about a {Flight}, including its blog entry and
  # {Photograph photos}.
  #
  # Routes
  # ------
  #
  # * `GET /flights/[id]`
  #
  # Path Parameters
  # ---------------
  #
  # |      |                           |
  # |:-----|:--------------------------|
  # | `id` | The slug of the {Flight}. |

  def show
    respond_with @flight
  end

  # Displays a page where a user can write or edit a flight's blog entry, and
  # upload {Photograph photos}.
  #
  # Routes
  # ------
  #
  # * `GET /flights/[id]/edit`
  #
  # Path Parameters
  # ---------------
  #
  # |      |                           |
  # |:-----|:--------------------------|
  # | `id` | The slug of the {Flight}. |

  def edit
    @flight.photographs.build
    respond_with @flight
  end

  # Displays a page where a user can write or edit a flight's blog entry, and
  # upload {Photograph photos}.
  #
  # Routes
  # ------
  #
  # * `PUT /flights/[id]/edit`
  #
  # Path Parameters
  # ---------------
  #
  # |      |                           |
  # |:-----|:--------------------------|
  # | `id` | The slug of the {Flight}. |
  #
  # Parameterized Hashes
  # --------------------
  #
  # |                      |                                                                                                     |
  # |:---------------------|:----------------------------------------------------------------------------------------------------|
  # | `flight`             | The attributes to update the flight with.                                                           |
  # | `flight[photograph]` | Nested attributes for the associated photographs. (Creating and destroying photographs is allowed.) |

  def update
    @flight.update_attributes params[:flight], as: :pilot
    respond_with @flight
  end

  private

  def find_flight
    @flight = subdomain_owner.flights.find_from_slug!(params[:id], request.subdomain)
  end

  def build_json(flights)
    flights.map do |flight|
      {
        id: flight.sequence,
        url: flight_url(flight),
        date: l(flight.date, format: :logbook),
        aircraft: {
          ident: flight.aircraft.ident,
          type: flight.aircraft.type
        },
        remarks: flight.remarks,
        duration: flight.duration,
        photos: flight.photographs.sample(4).map do |photo|
          {
            thumbnail: view_context.image_path(photo.image.url(:logbook)),
            full: view_context.image_path(photo.image.url),
            caption: photo.caption
          }
        end,
        occupants: flight.occupants.map do |occupant|
          {
            photo: view_context.image_path(occupant.person.photo.url(:logbook)),
            url: person_url(occupant.person),
            name: occupant.person.name
          }
        end
      }
    end
  end
end
