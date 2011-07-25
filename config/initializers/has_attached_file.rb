# Update has_attached_file to also optionally set a column indicating whether
# a file is attached.
#
# Also update it to include global storage configuration options.

class ActiveRecord::Base
  def self.has_attached_file_with_bool(name, options={})
    has_attached_file_without_bool name, options
    if column_names.include?("has_#{name}") then
      before_save { |obj| obj.send :"has_#{name}=", obj.send(name).original_filename.to_bool; true }
      scope :"with_#{name}", where(:"has_#{name}" => true)
      scope :"without_#{name}", where(:"has_#{name}" => false)
    end
  end

  def self.has_attached_file_with_configoro(name, options={})
    has_attached_file_without_configoro name,
                                        options.reverse_merge(Flightseein::Configuration.paperclip.symbolize_keys)
  end

  class << self
    alias_method_chain :has_attached_file, :bool
    alias_method_chain :has_attached_file, :configoro
  end
end
