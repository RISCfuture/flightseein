Flightseein::Application.configure do
   # Framework
  config.cache_classes = true # to prevent memcache bugs
  config.action_dispatch.best_standards_support = :builtin
  config.whiny_nils = true
  config.active_support.deprecation = :log
  config.cache_store = :memory_store

  # Controllers
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
end

Paperclip.options[:command_path] = File.join('', 'usr', 'local', 'bin')
