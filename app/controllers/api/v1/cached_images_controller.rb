# API endpoint for cached Airtable images.
# Returns the local cached URL or queues a background job to fetch it.
class Api::V1::CachedImagesController < ApplicationController
  skip_before_action :verify_authenticity_token

  # GET /api/v1/cached_images/:airtable_id
  # Params:
  #   - airtable_id: The Airtable record ID
  #   - url: The original Airtable image URL (required for caching)
  #
  # Returns JSON with:
  #   - cached: true/false
  #   - url: local image URL (if cached)
  def show
    airtable_id = params[:id]
    original_url = params[:url]

    return render json: { error: "Missing url parameter" }, status: :bad_request if original_url.blank?

    cached = CachedImage.find_by(airtable_id: airtable_id)

    if cached&.image&.attached? && !cached.expired?
      render json: {
        cached: true,
        url: rails_blob_path(cached.image, only_path: true)
      }
    else
      CacheImageJob.perform_later(airtable_id, original_url)
      render json: { cached: false }
    end
  end
end
