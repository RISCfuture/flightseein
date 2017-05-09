# Helper module for views of {FlightsController}.

module FlightsHelper

  # @return [true, false] Whether to use the two-column blog layout.

  def show_blog?
    @flight.blog.present? or subdomain_owner?
  end

  # @return [Integer] A dimensionless value indicating the precedence of a crew
  #   role; higher values have higher rank.

  def precedence(role)
    return 8 if role == "Commander"
    return 7 if role == "Pilot in command"
    return 6 if role == "Flight instructor"
    return 5 if role == "Second in command"
    return 4 if role == "Relief pilot"
    return 3 if role == "Safety pilot"
    return 2 if role == "Engineer"
    return 1 if role == "Student pilot"
    # other roles
    return -1 if role == "Observer"
    return -2 if role == "Flight attendant"

    return -100 if role.nil?

    return 0
  end
end
