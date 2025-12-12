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

  # Returns the screenshot URL for an entry via the live Airtable endpoint.
  #
  # @param entry [YswsProjectEntry] The project entry.
  # @return [String, nil] The screenshot endpoint URL.
  def cached_screenshot_url(entry)
    return nil if entry.airtable_id.blank?

    "/api/v1/screenshots/#{entry.airtable_id}"
  end
end
