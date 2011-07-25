# Be sure to restart your server when you modify this file.

Flightseein::Application.config.session_store :cookie_store, key: '_flightseein_session', domain: ".#{Flightseein::Configuration.routing.host}"

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Flightseein::Application.config.session_store :active_record_store

Flightseein::Application.config.action_dispatch.tld_length = Flightseein::Configuration.routing.tld_components
