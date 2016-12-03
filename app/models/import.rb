# A digital logbook file to import. Progress is recorded via the `state` field,
# which can take one of the following values:
#
# |                        |                                                |
# |:-----------------------|:-----------------------------------------------|
# | `pending`              | Processing has not yet begun.                  |
# | `starting`             | Processing is being initialized.               |
# | `importing_aircraft`   | {Aircraft} records are being imported.         |
# | `importing_airports`   | {Airport} records are being imported.          |
# | `importing_passengers` | {Person} records are being imported.           |
# | `importing_flights`    | {Flight} records are being imported.           |
# | `uploading_photos`     | Images are being converted and uploaded to S3. |
# | `completed`            | Processing completed successfully.             |
# | `failed`               | An error occurred during processing.           |
#
# Sidekiq handles the actual importing, which is queued by calling the
# {#enqueue} method.
#
# Fields
# --------
#
# |         |                       |
# |:--------|:----------------------|
# | `state` | The processing state. |
#
# Metadata
# --------
#
# |                        |                    |
# |:-----------------------|:-------------------|
# | `logbook_file_name`    | Used by Paperclip. |
# | `logbook_content_type` | Used by Paperclip. |
# | `logbook_file_size`    | Used by Paperclip. |
# | `logbook_updated_at`   | Used by Paperclip. |
# | `logbook_fingerprint`  | Used by Paperclip. |
#
# Associations
# ------------
#
# |        |                                             |
# |:-------|:--------------------------------------------|
# | `user` | The {User} whose logbook is being imported. |

class Import < ApplicationRecord
  include HasMetadataColumn

  # Supported logbook file MIME types.
  SUPPORTED_TYPES = %w( application/zip
                        application/x-gzip application/gzip
                        application/x-tar application/gnutar
                        application/x-bzip2 application/x-bzip
                        application/octet-stream )

  belongs_to :user, inverse_of: :imports

  has_metadata_column(
      logbook_file_name:    { allow_blank: true },
      logbook_content_type: { allow_blank: true },
      logbook_file_size:    { type: Fixnum, allow_blank: true, numericality: { less_than: 2.gigabytes } },
      logbook_updated_at:   { type: Time, allow_blank: true },
      logbook_fingerprint:  { allow_blank: true }
  )

  has_attached_file :logbook
  validates_attachment_content_type :logbook, content_type: SUPPORTED_TYPES

  # Enqueues this import for processing. Processing is performed by the
  # {ImporterJob}.

  def enqueue
    ImporterJob.perform_later self
  end

  # @return [Fixnum] A number from 0 to 6 indicating the progress of the import,
  #   or -1 if the import failed.

  def progress_value
    case state
      when :pending then 0
      when :starting then 1
      when :importing_aircraft then 2
      when :importing_airports then 3
      when :importing_passengers then 4
      when :importing_flights then 5
      when :uploading_photos then 6
      when :completed then 7
      else -1
    end
  end
end
