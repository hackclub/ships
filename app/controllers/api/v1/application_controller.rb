module Api
  module V1
    class ApplicationController < ActionController::API
        # Returns the currently logged-in user, if any.
  #
  # @return [User, nil] The current user or nil if not logged in.
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # Checks if a user is currently logged in.
  #
  # @return [Boolean] True if a user is logged in, false otherwise.
  def logged_in?
    current_user.present?
  end

       def require_login
    unless logged_in?
      redirect_to root_path, alert: "You must be logged in."
    end
  end
    end
  end
end