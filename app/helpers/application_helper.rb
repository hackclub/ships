module ApplicationHelper
  # Sanitizes a URL for safe use in href attributes.
  # Only allows http/https protocols to prevent javascript: XSS attacks.
  #
  # @param url [String, nil] The URL to sanitize.
  # @return [String, nil] The sanitized URL or nil if invalid.
  def safe_external_url(url)
    return nil if url.blank?

    uri = URI.parse(url.to_s.strip)
    return nil unless %w[http https].include?(uri.scheme&.downcase)

    url.to_s.strip
  rescue URI::InvalidURIError
    nil
  end
end
