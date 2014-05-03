# Update has_attached_file to also optionally set a column indicating whether
# a file is attached.
#
# Do not process invalid thumbnails.

class ActiveRecord::Base
  def self.has_attached_file_with_bool(name, options={})
    has_attached_file_without_bool name, options

    if options[:styles] then
      define_method :check_file_size do
        valid?
        errors[:"#{name}_file_size"].blank?
      end
      send :"before_#{name}_post_process", :check_file_size
    end

    if column_names.include?("has_#{name}") then
      before_save { |obj| obj.send :"has_#{name}=", obj.send(name).original_filename.to_bool; true }
      scope :"with_#{name}", -> { where(:"has_#{name}" => true) }
      scope :"without_#{name}", -> { where(:"has_#{name}" => false) }
    end
  end

  class << self
    alias_method_chain :has_attached_file, :bool
  end
end

# Also update it to include global storage configuration options.

Paperclip::Attachment.default_options.update Flightseein::Configuration.paperclip.symbolize_keys

# And add an interpolation that uses the content type to figure out the file's
# extension, rather than the file name

Paperclip.interpolates(:content_extension) do |attachment, style_name|
  ((style = attachment.styles[style_name]) && style[:format]) || begin
    fallback = File.extname(attachment.original_filename).gsub(/^\.+/, "")
    type     = MIME::Types[attachment.content_type].first
    return fallback unless type
    extension = type.extensions.first
    return extension || fallback
  end
end

# Disable media type spoof detection for some models.

class Paperclip::Validators::MediaTypeSpoofDetectionValidator < ActiveModel::EachValidator
  def validate_each_with_skipping(record, attribute, value)
    return if [Aircraft, Destination, Person].include?(record.class)
    validate_each_without_skipping(record, attribute, value)
  end
  alias_method_chain :validate_each, :skipping
end
