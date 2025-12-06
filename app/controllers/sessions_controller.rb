class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  # Handles the OmniAuth callback and logs the user in.
  def create
    auth = request.env["omniauth.auth"]
    user = find_or_create_user_from_api(auth)
    session[:user_id] = user.id

    redirect_to dash_path, notice: "Signed in successfully."
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
    user
  end
end
