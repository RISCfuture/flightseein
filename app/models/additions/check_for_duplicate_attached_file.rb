module CheckForDuplicateAttachedFile
  extend ActiveSupport::Concern

  module ClassMethods
    def check_for_duplicate_attached_file(*names)
      names.each do |name|

        define_method :"#{name}_with_dup_check=" do |file|
          attachment = send(name)
          old_fingerprint = attachment.fingerprint
          send :"#{name}_without_dup_check=", file
          if attachment.fingerprint == old_fingerprint then
            # restore to saved state
            attachment.instance_variable_set :@queued_for_delete, []
            attachment.instance_variable_set :@queued_for_write, {}
            attachment.instance_variable_set :@errors, {}
            attachment.instance_variable_set :@dirty, false
          end
        end
        alias_method_chain :"#{name}=", :dup_check
      end
    end
  end
end
