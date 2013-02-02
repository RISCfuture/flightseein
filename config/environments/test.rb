Flightseein::Application.configure do
  # Framework
  config.cache_classes = true
  config.whiny_nils    = true
  config.cache_store   = :memory_store

  # Logging
  config.active_support.deprecation = :stderr

  # Models
  config.active_record.mass_assignment_sanitizer = :strict

  # Views
  config.serve_static_assets = true
  config.static_cache_control = "public, max-age=3600"
  config.assets.allow_debugging = true

  # Controllers
  config.consider_all_requests_local                = true
  config.action_controller.perform_caching          = false
  config.action_dispatch.show_exceptions            = false
  config.action_controller.allow_forgery_protection = false
end
