# Helper module for views of {FlightsController}.

module FlightsHelper

  # @return [true, false] Whether to use the two-column blog layout.

  def show_blog?
    @blog or subdomain_owner?
  end
end
