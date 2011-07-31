Flightseein::Application.configure do
   # Framework
  config.cache_classes = true # to prevent memcache bugs
  config.whiny_nils    = true
  config.cache_store   = :memory_store

  # Logging
  #config.append_backtrace_to_log                = true
  config.active_support.deprecation             = :log
  config.action_dispatch.best_standards_support = :builtin


  # Controllers
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
end

Paperclip.options[:command_path] = File.join('', 'usr', 'local', 'bin')
