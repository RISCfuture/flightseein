# Be sure to restart your server when you modify this file.

Flightseein::Application.config.session_store :cookie_store,
                                              domain:       ".#{SubdomainRouter::Config.domain}",
                                              expire_after: 2.weeks,
                                              key:          '_flightseein_session'
