# Controller for importing digital logbooks.

class ImportsController < ApplicationController
  before_action :owner_login_required
  before_action :find_import, only: [ :show ]
  respond_to :html, :json

  # Displays a page where the user can upload and import a digital logbook.
  #
  # Routes
  # ------
  #
  # * `GET /imports/new`

  def new
    respond_with(@import = current_user.imports.new)
  end

  # Receives and imports a digital logbook.
  #
  #
  # Routes
  # ------
  #
  # * `POST /imports`
  #
  # Parameters
  # ----------
  #
  # |           |                      |
  # |:----------|:---------------------|
  # | `logbook` | The digital logbook. |

  def create
    @import = current_user.imports.create(import_params)
    @import.enqueue if @import.persisted?

    # [ :logbook_content_type, :logbook_file_size ].each do |field|
    #   @import.errors[field].each { |error| @import.errors[:logbook] << error }
    # end

    respond_with @import
  end

  # Displays the progress of an import operation.
  #
  #
  # Routes
  # ------
  #
  # * `GET /imports/:id`
  #
  # Route Components
  # ----------------
  #
  # |      |                                                  |
  # |:-----|:-------------------------------------------------|
  # | `id` | The auto-incrementing ID of the {Import} record. |

  def show
    respond_with @import do |format|
      format.json { render(json: @import.to_json(methods: :progress_value)) }
    end
  end

  private

  def find_import
    @import = current_user.imports.find_by_id(params[:id]) || raise(ActiveRecord::RecordNotFound)
  end

  def import_params
    params.require(:import).permit(:logbook)
  end
end
