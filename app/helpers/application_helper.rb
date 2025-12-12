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

  # Returns a cached screenshot URL for an entry, using local Active Storage.
  # Falls back to the original URL if not yet cached.
  #
  # @param entry [YswsProjectEntry] The project entry.
  # @return [String, nil] The cached or original screenshot URL.
  def cached_screenshot_url(entry)
    return nil if entry.screenshot_url.blank?

    cached = CachedImage.find_by(airtable_id: entry.airtable_id)

    if cached&.image&.attached? && !cached.expired?
      rails_blob_path(cached.image, only_path: true)
    else
      # Queue caching job and return original URL as fallback
      CacheImageJob.perform_later(entry.airtable_id, entry.screenshot_url)
      entry.screenshot_url
    end
  end
end
