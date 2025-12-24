# Handles user authentication via OmniAuth.
class SessionsController < ApplicationController
  # CSRF is handled by omniauth-rails_csrf_protection gem for OAuth callbacks.
  skip_before_action :verify_authenticity_token, only: :create

  # Handles the OmniAuth callback and logs the user in.
  # Includes session fixation protection via reset_session.
  def create
    auth = request.env["omniauth.auth"]
    user = find_or_create_user_from_api(auth)

    # SECURITY: Regenerate session ID to prevent session fixation attacks.
    reset_session
    session[:user_id] = user.id

    redirect_to dash_path, notice: "Signed in successfully."
  end

  # Handles authentication failures from OmniAuth.
  def failure
    redirect_to root_path, alert: "Authentication failed. Please try again."
  end

  # Logs the user out by clearing the session.
  # Includes session fixation protection via reset_session.
  def destroy
    # SECURITY: Destroy entire session to prevent session reuse.
    reset_session
    redirect_to root_path, notice: "Signed out successfully."
  end

  private

  # Fetches user info from the Hack Club API and finds or creates user by email.
  # This ensures each email gets its own user record, even if OAuth UID is shared.
  #
  # @param auth [OmniAuth::AuthHash] The auth hash from the OmniAuth callback.
  # @return [User] The found or created user.
  def find_or_create_user_from_api(auth)
    token = auth.credentials.token

    response = Faraday.get("https://auth.hackclub.com/api/v1/me") do |req|
      req.headers["Authorization"] = "Bearer #{token}"
    end

    data = JSON.parse(response.body)
    identity = data["identity"]
    email = identity["primary_email"]

    user = User.find_or_initialize_by(email: email)
    user.update!(
      provider: auth.provider,
      uid: auth.uid,
      access_token: token,
      slack_id: identity["slack_id"]
    )

    # Fetch Slack display name if missing
    if user.slack_id.present? && user.display_name_from_slack.blank?
      fetch_and_update_display_name(user)
    end

    user
  end

  # Fetches the Slack display name for a single user and updates the record.
  #
  # @param user [User] The user to update.
  def fetch_and_update_display_name(user)
    slack_token = Rails.application.credentials.dig(:slack, :bot_token)
    return unless slack_token.present?

    response = Faraday.get("https://slack.com/api/users.info") do |req|
      req.headers["Authorization"] = "Bearer #{slack_token}"
      req.params["user"] = user.slack_id
    end

    data = JSON.parse(response.body)
    return unless data["ok"]

    profile = data.dig("user", "profile") || {}
    display_name = profile["display_name"].presence || profile["real_name"].presence
    user.update_column(:display_name_from_slack, display_name) if display_name.present?
  rescue StandardError => e
    Rails.logger.error "[SessionsController] Failed to fetch Slack display name: #{e.message}"
  end
end
