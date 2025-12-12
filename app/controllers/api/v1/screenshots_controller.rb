# API endpoint that fetches fresh screenshot URLs directly from Airtable.
# This avoids storing expiring URLs in the database.
module Api
  module V1
    class ScreenshotsController < Api::V1::ApplicationController
      # GET /api/v1/screenshots/:airtable_id
      # Fetches the current screenshot URL from Airtable and redirects to it.
      def show
        airtable_id = params[:id]

        entry = YswsProjectEntry.find_by(airtable_id: airtable_id)
        unless entry
          return render json: { error: "Entry not found" }, status: :not_found
        end

        screenshot_url = fetch_screenshot_from_airtable(airtable_id)

        if screenshot_url.present?
          redirect_to screenshot_url, allow_other_host: true
        else
          render json: { error: "No screenshot available" }, status: :not_found
        end
      end

      private

      # Fetches the screenshot URL directly from Airtable.
      #
      # @param airtable_id [String] The Airtable record ID.
      # @return [String, nil] The screenshot URL or nil.
      def fetch_screenshot_from_airtable(airtable_id)
        Rails.cache.fetch("screenshot_url:#{airtable_id}", expires_in: 1.hour) do
          table = Norairrecord.table(
            Rails.application.credentials.dig(:airtable, :api_key),
            Rails.application.credentials.dig(:airtable, :base_id),
            "Approved Projects"
          )

          record = table.find(airtable_id)
          screenshot = record.fields["Screenshot"]
          screenshot.is_a?(Array) && screenshot.first ? screenshot.first["url"] : nil
        rescue StandardError => e
          Rails.logger.error "[ScreenshotsController] Failed to fetch screenshot for #{airtable_id}: #{e.message}"
          nil
        end
      end
    end
  end
end
