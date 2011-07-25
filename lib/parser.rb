# @abstract
#
# Abstract superclass for classes used to parse logbook formats. Subclasses must
# implement the {#process} method, which will import logbook records and create
# or update the appropriate model objects.

class Parser

  # Creates a new parser.
  #
  # @param [Import] import The import record.
  # @param [String] path The path to the decompressed, ready-to-process logbook
  #   file.

  def initialize(import, path)
    @path = path
    @import = import
  end

  # @abstract
  #
  # Implement this method to parse a logbook file. You can use the `@path` and
  # `@import` instance variables. (See the {#initialize} method.)

  def process
    raise NotImplementedError
  end

  protected

  # Sets the state of the import to "importing aircraft".
  def importing_aircraft!()   @import.update_attribute :state, :importing_aircraft   end
  # Sets the state of the import to "importing airports".
  def importing_airports!()   @import.update_attribute :state, :importing_airports   end
  # Sets the state of the import to "importing passengers".
  def importing_passengers!() @import.update_attribute :state, :importing_passengers end
  # Sets the state of the import to "importing flights".
  def importing_flights!()    @import.update_attribute :state, :importing_flights    end
  # Sets the state of the import to "uploading photos".
  def uploading_photos!()     @import.update_attribute :state, :uploading_photos     end

  # @return [User] The user who owns the import and to whom all imported records
  #   should belong.
  def user() @import.user end
end
