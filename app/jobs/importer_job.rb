class ImporterJob < ApplicationJob
  queue_as :default

  # Supported archive formats that can be decompressed.
  SUPPORTED_ARCHIVE_FORMATS = %w( .zip .gz .tar .bz2 .tgz .tbz )
  # Supported logbook formats.
  SUPPORTED_LOGBOOK_FORMATS = {
      /\.logten$/ => 'LogtenParser',
      /^LogTenProData$/ => 'LogtenSixParser'
  }

  # Attempts to decompress the logbook file (if necessary), then invokes the
  # correct {Parser} to do the importing.
  #
  # Should any exception occur, the import will be moved to the "failed" state.
  #
  # @param [Import] import The import to process.

  def perform(import)
    @import = import
    @uuid = SecureRandom.uuid
    @work_dir = Rails.root.join('tmp', 'work', @uuid).to_s

    @import.update_attribute :state, :starting

    path = download_file
    while SUPPORTED_ARCHIVE_FORMATS.include?(File.extname(path))
      path = decompress_file(path)
    end

    Dir.entries(@work_dir).each do |entry|
      next if entry.starts_with?('.')
      SUPPORTED_LOGBOOK_FORMATS.each do |rx, parser_name|
        if entry =~ rx then
          parser_name.constantize.new(@import, File.join(@work_dir, entry)).process
        end
      end
    end

    @import.update_attribute :state, :completed
  rescue Exception
    @import.update_attribute :state, :failed if @import
    raise
  ensure
    FileUtils.rm_rf @work_dir if @work_dir
  end

  private

  def download_file
    FileUtils.mkdir_p @work_dir
    name = @import.logbook.original_filename
    path = File.join(@work_dir, name)
    if Flightseein::Configuration.paperclip.storage == :s3 then
      File.open(path, 'wb') { |f| f.print open(@import.logbook.url).read }
    else
      File.open(path, 'wb') { |f| f.print open(@import.logbook.path).read }
    end
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
end
