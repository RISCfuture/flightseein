# Controller that returns JSON information about a set of
# {Photograph Photographs}, for use with the `Carousel` JavaScript class.
#
# This controller can be used as a root-level resource, in which case
# information about recent flights with photographs is returned. It can be
# nested under `flight`, in which case the photographs of a specific flight are
# returned.

class PhotographsController < ApplicationController
  before_action :find_flight
  respond_to :json

  # Returns information about a flight's photographs, or the photographs of any
  # recent flights that have at least one photo.
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
  # * `GET /photographs`
  # * `GET /flights/[flight_id]/photographs`
  #
  # Path Parameters
  # ---------------
  #
  # |             |                                                                                         |
  # |:------------|:----------------------------------------------------------------------------------------|
  # | `flight_id` | The slug for a {Flight}. Flights are limited to those belonging to the subdomain owner. |

  def index
    respond_to do |format|
      format.json do
        if @flight then
          @photographs = @flight.photographs.order('id ASC').limit(10)
          if params['last_record'] and params['last_record'].to_i > 0 then
            @photographs = @photographs.where('id > ?', params['last_record'].to_i)
          end
          render(json: build_json(@photographs).to_json)
        else
          @flights = Flight.where(has_photos: true).includes(:user).order('date DESC, id DESC').limit(5)
          if params['last_record'] and params['last_record'].to_i > 0 then
            @flights = @flights.where(false) # only allow the 5 most recent photos
          end
          render(json: build_json_from_flights(@flights).to_json)
        end
      end
    end
  end

  def create
    respond_with (@photograph = @flight.photographs.create(photograph_params)),
                 location: flight_url(@flight, subdomain: @flight.user.subdomain)
  end

  private

  def find_flight
    return true unless subdomain_owner
    @flight = Flight.find_from_slug!(params[:flight_id], request.subdomain)
  end

  def build_json(photos)
    photos.map do |photo|
      {
          id:          photo.id,
          url:         view_context.image_path(photo.image.url),
          preview_url: view_context.image_path(photo.image.url(:carousel)),
          caption:     photo.caption
      }
    end
  end

  def build_json_from_flights(flights)
    flights.map { |f| f.photographs.limit(5).sample }.map do |photo|
      {
          id:          photo.id,
          url:         flight_url(photo.flight, subdomain: photo.flight.user.subdomain),
          preview_url: view_context.image_path(photo.image.url(:carousel)),
          caption:     photo.caption
      }
    end
  end

  def photograph_params
    params.require(:photograph).permit(:image, :caption)
  end
end
