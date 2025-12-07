# Rack::Attack configuration for rate limiting and abuse prevention.
# See: https://github.com/rack/rack-attack

class Rack::Attack
  # Throttle login attempts by IP address.
  # Limit to 5 requests per 20 seconds per IP.
  throttle("auth/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path.start_with?("/auth/") || req.path == "/oauth/callback"
  end

  # Throttle GitHub stars fetching to prevent API abuse.
  # Limit to 10 requests per minute per IP.
  throttle("fetch_stars/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path.include?("/fetch_stars")
  end

  # Throttle virality stats fetching to prevent Airtable API abuse.
  # Limit to 10 requests per minute per IP.
  throttle("virality/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path.include?("/virality")
  end

  # Throttle cached images endpoint to prevent SSRF/DoS.
  # Limit to 30 requests per minute per IP.
  throttle("cached_images/ip", limit: 30, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/v1/cached_images")
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
