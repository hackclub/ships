class AdminController < ApplicationController
  before_action :require_admin

  def index
  end

  # Lists all users for impersonation selection.
  def users
    @users = User.order(:email)
  end

  # Impersonates a user and redirects to their dashboard.
  def impersonate
    user = User.find(params[:id])
    session[:impersonated_user_id] = user.id
    session.delete(:impersonated_email)
    redirect_to dash_path, notice: "Now viewing as #{user.display_name}"
  end

  # Impersonates by email (creates temp user if not found).
  def impersonate_by_email
    email = params[:email].to_s.strip.downcase
    if email.blank?
      redirect_to admin_users_path, alert: "Email is required"
      return
    end

    user = User.find_or_create_by(email: email)
    session[:impersonated_user_id] = user.id
    session.delete(:impersonated_email)
    redirect_to dash_path, notice: "Now viewing as #{email}"
  end

  # Stops impersonating and returns to admin view.
  def stop_impersonating
    session.delete(:impersonated_user_id)
    redirect_to admin_path, notice: "Stopped impersonating"
  end

  private

  # Ensures the user is an admin before accessing admin pages.
  def require_admin
    unless real_current_user&.admin?
      head :forbidden
    end
  end
end
