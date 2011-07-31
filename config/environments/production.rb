Flightseein::Application.configure do
  # Framework
  config.cache_classes              = true
  config.i18n.fallbacks             = true
  config.active_support.deprecation = :notify
  config.cache_store                = :mem_cache_store

  # Controllers
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Sendfile" # Use 'X-Accel-Redirect' for nginx

  # Views
  config.serve_static_assets  = false
  config.assets.js_compressor = :uglifier
  #config.assets.css_compressor = :scss
end
