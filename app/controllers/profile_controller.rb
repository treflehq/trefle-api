class ProfileController < ApplicationController

  # Send anonymous visitors to the sign-in page rather than a bare
  # 401 redirect to the home page.
  before_action :authenticate_user!

  def index; end
end
