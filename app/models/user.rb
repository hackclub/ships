class User < ApplicationRecord
  has_encrypted :access_token

  # Finds or creates a user from OmniAuth callback data.
  #
  # @param auth [OmniAuth::AuthHash] The auth hash from the OmniAuth callback.
  # @return [User] The found or created user.
  def self.from_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
      user.access_token = auth.credentials.token
    end
  end

  # Checks if the user has admin privileges.
  #
  # @return [Boolean] True if the user is an admin, false otherwise.
  def admin?
    admin == true
  end
  def display_name
    return email.split("@")[0] unless display_name_from_slack
    display_name_from_slack
  end
end
