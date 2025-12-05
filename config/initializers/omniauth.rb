OmniAuth.config.allowed_request_methods = %i[post get]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.request_validation_phase = nil

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
