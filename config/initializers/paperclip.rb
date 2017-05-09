require File.join(File.dirname(__FILE__), 'recursively')

# Also update it to include global storage configuration options.

Paperclip::Attachment.default_options.update Flightseein::Configuration.paperclip.symbolize_keys.recursively!(&:symbolize_keys!)

# And add an interpolation that uses the content type to figure out the file's
# extension, rather than the file name

Paperclip.interpolates(:content_extension) do |attachment, style_name|
  ((style = attachment.styles[style_name]) && style[:format]) || begin
    fallback = File.extname(attachment.original_filename).gsub(/^\.+/, '')
    type     = MIME::Types[attachment.content_type].first
    return fallback unless type
    extension = type.extensions.first
    return extension || fallback
  end
end

# Disable media type spoof detection for some models.

module PaperclipDisableSpoofDetection
  def validate_each(record, attribute, value)
    return if [Aircraft, Destination, Person].include?(record.class)
    super
  end
end

Paperclip::Validators::MediaTypeSpoofDetectionValidator.prepend PaperclipDisableSpoofDetection
