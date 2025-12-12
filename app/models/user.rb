class User < ApplicationRecord
  has_encrypted :access_token

  before_create :generate_api_key

  # Finds or creates a user from OmniAuth callback data.
  #
  # @param auth [OmniAuth::AuthHash] The auth hash from the OmniAuth callback.
  # @return [User] The found or created user.
  def self.from_omniauth(auth)
    find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
      user.access_token = auth.credentials.token
    end
  end

  # Generates a new API key for the user.
  #
  # @return [String] The new API key.
  def regenerate_api_key!
    update!(api_key: SecureRandom.hex(32))
    api_key
  end

  # Checks if the user has admin privileges.
  #
  # @return [Boolean] True if the user is an admin, false otherwise.
  def admin?
    admin == true
  end

  # Returns a user's display name, falling back to the email prefix.
  #
  # @return [String] The display name.
  def display_name
    return email.split("@")[0] unless display_name_from_slack
    display_name_from_slack
  end

  private

  # Generates a unique API key for the user on creation.
  def generate_api_key
    self.api_key ||= SecureRandom.hex(32)
  end
end
