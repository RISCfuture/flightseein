# Controller for viewing a {User}'s {Person passengers}.

class PeopleController < ApplicationController
  respond_to :html, :json
  before_filter :find_person, only: :show

  # HTML
  # ====
  #
  # Displays a page that dynamically loads a grid of passengers' faces.
  #
  # JSON
  # ====
  #
  # Returns information about passengers in 50-long pages; used by the HTML
  # view. Passengers are sorted by total hours descending.
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
  # * `GET /people`

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json do
        people = subdomain_owner.people.
          includes(:metadata, :slugs).
          participating.
          not_me.
          order('hours DESC, id DESC').
          limit(50)

        if params['last_record'] then
          last_person = subdomain_owner.people.find_by_id(params['last_record'])
          people = people.where('hours < ? OR (hours = ? AND id < ?)', last_person.hours, last_person.hours, last_person.id) if last_person
        end

        render(json: build_json(people).to_json)
      end
    end
  end

  # Displays information about a {Person}, including a list of {Flight Flights}
  # they've been on.
  #
  # Routes
  # ------
  #
  # * `GET /people/[id]`
  #
  # Path Parameters
  # ---------------
  #
  # |      |                           |
  # |:-----|:--------------------------|
  # | `id` | The slug of the {Person}. |

  def show
    respond_with @person
  end

  private

  def build_json(people)
    people.map do |person|
      {
        id: person.id,
        name: person.name,
        url: person_url(person),
        hours: person.hours,
        flights: person.flights.count,
        photo: view_context.image_path(person.photo.url(:carousel))
      }
    end
  end

  def find_person
    @person = Person.find_from_slug(params[:id], request.subdomain)
  end
end
