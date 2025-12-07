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
    Rails.logger.info "[ADMIN] #{real_current_user.email} started impersonating #{user.email}"
    session[:impersonated_user_id] = user.id
    session.delete(:impersonated_email)
    redirect_to dash_path, notice: "Now viewing as #{user.display_name}"
  end

  # Impersonates by email (user must already exist for security).
  def impersonate_by_email
    email = params[:email].to_s.strip.downcase
    if email.blank?
      redirect_to admin_users_path, alert: "Email is required"
      return
    end

    # SECURITY: Only allow impersonation of existing users to prevent
    # accidental user record creation and potential abuse.
    user = User.find_by(email: email)
    unless user
      redirect_to admin_users_path, alert: "User not found: #{email}"
      return
    end

    Rails.logger.info "[ADMIN] #{real_current_user.email} started impersonating #{user.email}"
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
      redirect_to root_path, alert: "You must be an admin to access this page."
    end
  end
end
