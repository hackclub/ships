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

  # Impersonates by email (creates user if not found).
  def impersonate_by_email
    email = params[:email].to_s.strip.downcase
    if email.blank?
      redirect_to admin_users_path, alert: "Email is required"
      return
    end

    # Find or create user for impersonation
    user = User.find_or_create_by(email: email) do |u|
      u.provider = "impersonation"
      u.uid = SecureRandom.uuid
    end

    Rails.logger.info "[ADMIN] #{real_current_user.email} started impersonating #{user.email}"
    session[:impersonated_user_id] = user.id
    redirect_to dash_path, notice: "Now viewing as #{email}"
  end

  # Stops impersonating and returns to admin view.
  def stop_impersonating
    session.delete(:impersonated_user_id)
    redirect_to admin_path, notice: "Stopped impersonating"
  end

  # Triggers the Airtable sync job manually.
  def trigger_sync
    AirtableJob.perform_later
    redirect_to admin_path, notice: "Airtable sync job queued successfully"
  end

  private

  # Ensures the user is an admin before accessing admin pages.
  def require_admin
    unless real_current_user&.admin?
      redirect_to root_path, alert: "You must be an admin to access this page."
    end
  end
end
