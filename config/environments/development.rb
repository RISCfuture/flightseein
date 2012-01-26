Flightseein::Application.configure do
   # Framework
  config.cache_classes = true # to prevent memcache bugs
  config.whiny_nils    = true
  config.cache_store   = :memory_store

  # Logging
  #config.append_backtrace_to_log                = true
  config.active_support.deprecation             = :log
  config.action_dispatch.best_standards_support = :builtin

  # Models
  config.active_record.mass_assignment_sanitizer = :strict
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Controllers
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Views
  config.assets.compress = false
  config.assets.debug = true
end

Paperclip.options[:command_path] = File.join('', 'usr', 'local', 'bin')
