class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  # Handles the OmniAuth callback and logs the user in.
  def create
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)
    session[:user_id] = user.id

    # Fetch user info from the API and update the user record
    fetch_and_update_user_info(user, auth.credentials.token)

    redirect_to root_path, notice: "Signed in successfully."
  end

  # Handles authentication failures from OmniAuth.
  def failure
    redirect_to root_path, alert: "Authentication failed: #{params[:message]}"
  end

  # Logs the user out by clearing the session.
  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Signed out successfully."
  end

  private

  # Fetches user info from the Hack Club API and updates the user record.
  #
  # @param user [User] The user to update.
  # @param token [String] The OAuth access token.
  def fetch_and_update_user_info(user, token)
    response = Faraday.get("https://auth.hackclub.com/api/v1/me") do |req|
      req.headers["Authorization"] = "Bearer #{token}"
    end

    data = JSON.parse(response.body)
    identity = data["identity"]

    user.update(
      email: identity["primary_email"],
      slack_id: identity["slack_id"]
    )
  end
end
