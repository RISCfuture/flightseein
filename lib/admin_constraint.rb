# A constraint for use in routes files that ensures only admin users can access
# a route.

class AdminConstraint
  # @private
  def matches?(request)
    return false unless request.session[:user_id]
    user = User.find(request.session[:user_id])
    user && user.admin?
  end
end
