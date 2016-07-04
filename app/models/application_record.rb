class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Update has_attached_file to also optionally set a column indicating whether
  # a file is attached.
  #
  # Do not process invalid thumbnails.

  def self.has_attached_file(name, options={})
    super

    if options[:styles] then
      define_method :check_file_size do
        validate
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
end
