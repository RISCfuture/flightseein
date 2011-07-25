require 'securerandom'
require 'open-uri'
require 'parser/logten_parser'

# Prepares an uploaded logbook file for importing and delegates the importing
# to the appropriate {Parser}.

class Importer
  # Supported archive formats that can be decompressed.
  SUPPORTED_ARCHIVE_FORMATS = %w( .zip .gz .tar .bz2 .tgz .tbz )
  # Supported logbook formats.
  SUPPORTED_LOGBOOK_FORMATS = {
    '.logten' => 'LogtenParser'
  }

  # Creates a new importer.
  #
  # @param [Import] import The import record.

  def initialize(import)
    @import = import
    @uuid = SecureRandom.uuid
    @work_dir = Rails.root.join('tmp', 'work', @uuid).to_s
  end
  
  # Attempts to decompress the logbook file (if necessary), then invokes the
  # correct {Parser} to do the importing.
  #
  # Should any exception occur, the import will be moved to the "failed" state.

  def perform
    @import.update_attribute :state, :starting

    path = download_file
    while SUPPORTED_ARCHIVE_FORMATS.include?(File.extname(path))
      path = decompress_file(path)
    end

    Dir.entries(@work_dir).each do |entry|
      next if entry.starts_with?('.')
      next unless SUPPORTED_LOGBOOK_FORMATS.include?(File.extname(entry))
      process_file File.join(@work_dir, entry)
    end

    @import.update_attribute :state, :completed
  rescue Exception
    @import.update_attribute :state, :failed
    raise
  ensure
    FileUtils.rm_rf @work_dir
  end

  private

  def download_file
    FileUtils.mkdir_p @work_dir
    name = File.basename(@import.logbook.path)
    path = File.join(@work_dir, name)
    File.open(path, 'wb') { |f| f.print open(@import.logbook.url).read }
    return path
  end

  def decompress_file(path)
    if path.ends_with?('.tar') then
      system 'tar', 'xf', path, '-C', @work_dir
      return path.sub /\.tar$/, ''
    elsif path.ends_with?('.tgz') then
      system 'tar', 'xzf', path, '-C', @work_dir
      return path.sub /\.tgz$/, ''
    elsif path.ends_with?('.tbz') then
      system 'tar', 'xjf', path, '-C', @work_dir
      return path.sub /\.tbz$/, ''
    elsif path.ends_with?('.gz') then
      system 'gunzip', path
      return path.sub /\.gz$/, ''
    elsif path.ends_with?('.bz2') then
      system 'bunzip2', path
      return path.sub /\.bz2$/, ''
    elsif path.ends_with?('.zip') then
      system 'unzip', '-d', @work_dir, path
      return path.sub /\.zip$/, ''
    else
      return path
    end
  end

  def process_file(path)
    SUPPORTED_LOGBOOK_FORMATS[File.extname(path)].constantize.new(@import, path).process
  end
end
