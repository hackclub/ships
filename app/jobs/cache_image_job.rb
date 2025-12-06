# Background job to fetch and cache Airtable images.
# Airtable image URLs expire after ~2 hours, so we download and store them locally.
class CacheImageJob < ApplicationJob
  queue_as :default

  # @param airtable_id [String] The Airtable record ID
  # @param original_url [String] The Airtable image URL to download
  def perform(airtable_id, original_url)
    return if original_url.blank?

    cached = CachedImage.find_or_initialize_by(airtable_id: airtable_id)

    # Skip if image is still valid
    return if cached.persisted? && cached.image.attached? && !cached.expired?

    # Download the image
    response = Faraday.get(original_url)
    return unless response.success?

    # Determine content type and filename
    content_type = response.headers["content-type"] || "image/jpeg"
    extension = Rack::Mime::MIME_TYPES.invert[content_type] || ".jpg"
    filename = "#{airtable_id}#{extension}"

    # Attach the image
    cached.image.attach(
      io: StringIO.new(response.body),
      filename: filename,
      content_type: content_type
    )

    # Set expiration (1.5^3 ≈ 3.375 days)
    cached.original_url = original_url
    cached.expires_at = 3.375.days.from_now
    cached.save!
  rescue Faraday::Error => e
    Rails.logger.error("Failed to cache image #{airtable_id}: #{e.message}")
  end
end
