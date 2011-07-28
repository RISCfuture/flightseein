# Controller for modifying and deleting a {User}'s account.

class AccountsController < ApplicationController
  before_filter :owner_login_required, only: [ :edit, :update, :destroy ]
  respond_to :html

  # Displays information about a {User}. This serves as the user's home page.
  #
  # Routes
  # ------
  #
  # * `GET /`

  def show
    @flight_count = subdomain_owner.flights.count
    @pax_count = subdomain_owner.people.participating.not_me.count
    @airport_count = subdomain_owner.destinations.count

    @flight_images = subdomain_owner.flights.includes(photographs: :metadata, stops: { destination: { airport: :slug } }).order('sequence DESC').limit(4)

    @pax_images = subdomain_owner.people.with_photo.participating.not_me.limit(50).sample(4)
    @pax_images += subdomain_owner.people.without_photo.participating.not_me.limit(50).sample(4 - @pax_images.size) unless @pax_images.size == 4
    @pax_images.shuffle!

    @airport_images = subdomain_owner.destinations.with_photo.limit(50).sample(4)
    @airport_images += subdomain_owner.destinations.without_photo.limit(50).sample(4 - @airport_images.size) unless @airport_images.size == 4
    @airport_images.shuffle!

    if subdomain_owner.quote.present? then
      @quote = Redcarpet.new(subdomain_owner.quote)
      @quote.smart = true
      @quote.no_image = true
      @quote.safelink = true
      @quote.autolink = true
    end

    respond_with current_user
  end

  # Displays a page where a {User} can edit his information.
  #
  # Routes
  # ------
  #
  # * `GET /account/edit`

  def edit
    respond_with current_user
  end

  # Updates the current {User}.
  #
  # Routes
  # ------
  #
  # * `PUT /account`
  #
  # Parameterized Hashes
  # --------------------
  #
  # |        |                                       |
  # |:-------|:--------------------------------------|
  # | `user` | The information for the user account. |

  def update
    current_user.update_attributes(params[:user])
    respond_with current_user do |format|
      format.html do
        if current_user.valid? then
          redirect_to root_url(subdomain: current_user.subdomain)
        else
          render 'edit'
        end
      end
    end
  end

  # Deletes a {User} account and logs the user out.
  #
  # Routes
  # ------
  #
  # * `DELETE /account`

  def destroy
    current_user.update_attribute :active, false
    log_out
    
    respond_to do |format|
      format.html { redirect_to root_url, notice: t('controllers.accounts.destroy.done') }
    end
  end
end
