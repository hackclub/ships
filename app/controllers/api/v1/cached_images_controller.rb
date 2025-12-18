# API endpoint for cached Airtable images.
# Returns the local cached URL or queues a background job to fetch it.
#
# SECURITY: This controller validates URLs to prevent SSRF attacks and
# inherits from the API base controller for proper session handling.
module Api
  module V1
    class CachedImagesController < Api::V1::ApplicationController
      # Allowed hosts for image caching (Airtable CDN domains).
      ALLOWED_IMAGE_HOSTS = [
        "v5.airtableusercontent.com",
        "dl.airtable.com",
        ".airtableusercontent.com"
      ].freeze

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

        if original_url.blank?
          return render json: { error: "Missing url parameter" }, status: :bad_request
        end

        # SECURITY: Validate URL to prevent SSRF attacks.
        unless valid_image_url?(original_url)
          return render json: { error: "Invalid url - only Airtable image URLs are allowed" }, status: :unprocessable_entity
        end

        cached = CachedImage.find_by(airtable_id: airtable_id)

        if cached&.image&.attached? && !cached.expired?
          render json: {
            cached: true,
            url: Rails.application.routes.url_helpers.rails_blob_path(cached.image, only_path: true)
          }
        else
          CacheImageJob.perform_later(airtable_id, original_url)
          render json: { cached: false }
        end
      end

      private

      # Validates that the URL is a safe, allowed image URL.
      # Only allows HTTPS URLs from trusted Airtable domains.
      #
      # @param url [String] The URL to validate.
      # @return [Boolean] True if URL is valid and allowed.
      def valid_image_url?(url)
        uri = URI.parse(url)

        # Only allow HTTPS.
        return false unless uri.is_a?(URI::HTTPS)

        # Check against allowed hosts.
        host = uri.host&.downcase
        return false if host.nil?

        ALLOWED_IMAGE_HOSTS.any? do |allowed|
          if allowed.start_with?(".")
            host.end_with?(allowed)
          else
            host == allowed
          end
        end
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
