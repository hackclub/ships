# Stores cached Airtable images to avoid expiring URLs.
# Images are stored using Active Storage and refreshed via background jobs.
class CachedImage < ApplicationRecord
  has_one_attached :image

  validates :airtable_id, presence: true, uniqueness: true

  # Check if the cached image has expired (Airtable URLs expire after ~2 hours)
  def expired?
    expires_at.nil? || expires_at < Time.current
  end

  # Returns the local image URL if available and not expired, otherwise queues a refresh.
  # @param airtable_id [String] The Airtable record ID
  # @param original_url [String] The original Airtable image URL
  # @return [String, nil] The local image URL or nil if not yet cached
  def self.url_for(airtable_id, original_url)
    cached = find_by(airtable_id: airtable_id)

    if cached&.image&.attached? && !cached.expired?
      Rails.application.routes.url_helpers.rails_blob_path(cached.image, only_path: true)
    else
      CacheImageJob.perform_later(airtable_id, original_url)
      nil
    end
  end
end
