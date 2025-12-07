# OmniAuth configuration for Hack Club authentication.
# Uses POST-only OAuth flow with proper CSRF protection.

# SECURITY: Use POST-only for OAuth initiation to prevent login CSRF attacks.
# The omniauth-rails_csrf_protection gem handles state/nonce verification.
OmniAuth.config.allowed_request_methods = [ :post ]

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :oauth2,
    Rails.application.credentials.dig(:idv, :client_id),
    Rails.application.credentials.dig(:idv, :client_secret),
    {
      name: :hack_club,
      scope: "profile email slack_id",
      callback_path: "/oauth/callback",
      client_options: {
        site: "https://auth.hackclub.com",
        authorize_url: "/oauth/authorize",
        token_url: "/oauth/token"
      }
    }
end
