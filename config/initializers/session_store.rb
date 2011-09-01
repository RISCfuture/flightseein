# Be sure to restart your server when you modify this file.

Flightseein::Application.config.session_store :cookie_store, domain: ".#{Flightseein::Configuration.routing.host}", expire_after: 2.weeks, key: '_flightseein_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Flightseein::Application.config.session_store :active_record_store

Flightseein::Application.config.action_dispatch.tld_length = Flightseein::Configuration.routing.tld_components
