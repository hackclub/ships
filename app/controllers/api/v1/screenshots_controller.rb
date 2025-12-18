# API endpoint that fetches fresh screenshot URLs directly from Airtable.
# This avoids storing expiring URLs in the database.
module Api
  module V1
    class ScreenshotsController < Api::V1::ApplicationController
      # Allowed hosts for screenshot redirects (Airtable CDN domains).
      ALLOWED_SCREENSHOT_HOSTS = %w[
        v5.airtableusercontent.com
        dl.airtable.com
      ].freeze

      # GET /api/v1/screenshots/:airtable_id
      # Fetches the current screenshot URL from Airtable and redirects to it.
      def show
        airtable_id = params[:id]

        entry = YswsProjectEntry.find_by(airtable_id: airtable_id)
        unless entry
          return render json: { error: "Entry not found" }, status: :not_found
        end

        screenshot_url = fetch_screenshot_from_airtable(airtable_id)
        validated_url = validate_and_return_url(screenshot_url)

        if validated_url
          redirect_to validated_url, allow_other_host: true # brakeman:disable:Redirect
        else
          render json: { error: "No screenshot available" }, status: :not_found
        end
      end

      private

      # Validates and returns the URL only if it's from allowed domains.
      #
      # @param url [String, nil] The URL to validate.
      # @return [String, nil] The validated URL or nil.
      def validate_and_return_url(url)
        return nil if url.blank?

        uri = URI.parse(url)
        return nil unless uri.is_a?(URI::HTTPS)

        host = uri.host&.downcase
        return nil unless ALLOWED_SCREENSHOT_HOSTS.any? { |allowed| host&.end_with?(allowed) }

        url
      rescue URI::InvalidURIError
        nil
      end

      # Fetches the screenshot URL directly from Airtable.
      #
      # @param airtable_id [String] The Airtable record ID.
      # @return [String, nil] The screenshot URL or nil.
      def fetch_screenshot_from_airtable(airtable_id)
        Rails.cache.fetch("screenshot_url:#{airtable_id}", expires_in: 1.hour) do
          record = HackclubAirtable.find("Approved Projects", airtable_id)
          return nil unless record

          fields = record["fields"] || record
          screenshot = fields["Screenshot"]
          screenshot.is_a?(Array) && screenshot.first ? screenshot.first["url"] : nil
        rescue StandardError => e
          Rails.logger.error "[ScreenshotsController] Failed to fetch screenshot for #{airtable_id}: #{e.message}"
          nil
        end
      end
    end
  end
end
