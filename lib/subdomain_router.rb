# Module for working with custom subdomains. Each {User} is afforded his own
# subdomain.

module SubdomainRouter

  # Controller mixin that adds subdomain management features.

  module Controller
    extend ActiveSupport::Concern

    included do
      helper_method(:subdomain_owner, :url_for) if respond_to?(:helper_method)
    end

    # Adds to the `url_for` method the ability to route to different subdomains.
    # Thus, all URL generation (including smart route methods) gains the
    # `:subdomain` options.
    #
    # For more information, see the Rails documentation.
    #
    # @param [Hash] options Options for the URL.
    # @option options [String, nil, false] :subdomain The subdomain to route to.
    #   If `false`, uses the default subdomain (e.g., "www"). If `nil`, uses the
    #   current subdomain.
    # @return [String] The generated URL.
    # @raise [ArgumentError] If the `:subdomain` option is invalid.

    def url_for(options={})
      return super unless options.is_a?(Hash)

      case options[:subdomain]
        when nil
          options.delete :subdomain
          super options
        when false, String
          subdomain = options.delete(:subdomain) || Flightseein::Configuration.routing.default_subdomain
          host = options[:host] || (respond_to?(:request) && request.host) || Flightseein::Configuration.routing.host
          host_parts = host.split('.').last(Flightseein::Configuration.routing.tld_components + 1)
          host_parts.unshift subdomain
          host_parts.delete_if &:blank?
          super options.merge(host: host_parts.join('.'))
        else
          raise ArgumentError, ":subdomain must be nil, false, or a string"
      end
    end

    protected

    # @return [User, nil] The user that owns the current subdomain, or `nil` for
    #   the default subdomain (e.g., "www").

    def subdomain_owner
      request.env['subdomain_router.subdomain_owner'] || User.active.for_subdomain(request.subdomain).first
    end
  end

  # A routing constraint that restricts routes to only valid user subdomains.
  #
  # @example
  #   get 'home' => 'accounts#show', constraint: SubdomainRouter::Constraint

  module Constraint

    # Determines if a given request has a custom user subdomain.
    #
    # @param [ActionDispatch::Request] request An HTTP request.
    # @return [true, false] Whether the request subdomain matches a known user
    #   subdomain.

    def matches?(request)
      return false unless request.subdomains.size == 1
      return false if request.subdomains.first == Flightseein::Configuration.routing.default_subdomain
      return subdomain?(request)
    end
    module_function :matches?

    private

    def subdomain?(request)
      subdomain = request.subdomains.first.downcase
      user = Rails.cache.fetch("User/#{subdomain}") do
        User.active.for_subdomain(subdomain).first
      end
      request.env['subdomain_router.subdomain_owner'] = user
      user
    end
    module_function :subdomain?
  end
end
