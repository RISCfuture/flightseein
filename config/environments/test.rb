Flightseein::Application.configure do
  # Framework
  config.cache_classes = true
  config.whiny_nils = true
  config.active_support.deprecation = :stderr
  config.cache_store = :memory_store

  # Views
  config.serve_static_assets = true
  config.static_cache_control = "public, max-age=3600"

  # Controllers
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection    = false

  # Mailers
  config.action_mailer.delivery_method = :test
end

Resque.inline = true
