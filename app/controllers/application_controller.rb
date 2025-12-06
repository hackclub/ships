class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?, :impersonating?, :real_current_user

  # Returns the currently logged-in user, if any.
  # If impersonating, returns the impersonated user.
  #
  # @return [User, nil] The current user or nil if not logged in.
  def current_user
    if impersonating?
      @impersonated_user ||= User.find_by(id: session[:impersonated_user_id])
    else
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end
  end

  # Returns the real admin user (not the impersonated one).
  #
  # @return [User, nil] The real admin user.
  def real_current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # Checks if we are currently impersonating a user.
  #
  # @return [Boolean] True if impersonating.
  def impersonating?
    session[:impersonated_user_id].present? && real_current_user&.admin?
  end

  # Checks if a user is currently logged in.
  #
  # @return [Boolean] True if a user is logged in, false otherwise.
  def logged_in?
    current_user.present?
  end

  # Used by audits1984 to identify the auditor.
  #
  # @return [User, nil] The current user if they are an admin.
  def find_current_auditor
    current_user if current_user&.admin?
  end

  private

  # Ensures the user is logged in before accessing certain actions.
  def require_login
    unless logged_in?
      redirect_to root_path, alert: "You must be logged in."
    end
  end
end
