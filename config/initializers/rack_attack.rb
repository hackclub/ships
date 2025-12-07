# Rack::Attack configuration for rate limiting and abuse prevention.
# See: https://github.com/rack/rack-attack

# Only enable in production to avoid cache table issues in dev/test.
Rack::Attack.enabled = Rails.env.production?

class Rack::Attack
  # Only apply rate limiting to API endpoints.
  # Throttle API endpoints by IP address.
  # Limit to 100 requests per minute per IP.
  throttle("api/ip", limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/v1/")
  end

  # Throttle admin API endpoints more strictly.
  # Limit to 60 requests per minute per IP.
  throttle("admin_api/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/v1/admin")
  end

  # Block suspicious requests (optional safelist/blocklist).
  # Uncomment and configure as needed:
  # blocklist("block bad IPs") do |req|
  #   # Block specific IPs
  #   ["1.2.3.4", "5.6.7.8"].include?(req.ip)
  # end

  # Custom response for throttled requests.
  self.throttled_responder = lambda do |env|
    match_data = env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ { error: "Rate limit exceeded. Retry after #{retry_after} seconds." }.to_json ]
    ]
  end
end
