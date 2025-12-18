# OmniAuth configuration for Hack Club authentication.

# Allow both GET and POST for OAuth initiation for compatibility.
OmniAuth.config.allowed_request_methods = [ :get, :post ]
OmniAuth.config.silence_get_warning = true

# Log failures for debugging.
OmniAuth.config.on_failure = Proc.new do |env|
  message = env["omniauth.error.type"]
  Rails.logger.error "[OmniAuth] Failure: #{message} - #{env['omniauth.error']&.message}"
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end

OmniAuth.config.logger = Rails.logger

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
