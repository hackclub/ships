module Api
  module V1
    class YswsEntriesController < ApplicationController
      # GET /api/v1/ysws_entries
      # Returns YSWS project entries from the last 6 months as JSON, cached for 10 minutes.
      # Use ?all=true to get all entries (slower).
      def index
        cache_key = params[:all] == "true" ? "api/v1/ysws_entries/all" : "api/v1/ysws_entries"

        entries = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
          scope = YswsProjectEntry
            .where.not(ysws: "Boba Drops")
            .select(:airtable_id, :ysws, :approved_at, :code_url, :country, :playable_url,
                    :description, :github_username, :heard_through, :hours_spent,
                    :hours_spent_actual, :screenshot_url, :github_stars)

          scope = scope.where("approved_at >= ?", 6.months.ago) unless params[:all] == "true"

          scope.map do |entry|
            {
              id: entry.airtable_id,
              ysws: entry.ysws,
              approved_at: entry.approved_at&.to_i || "null",
              code_url: entry.code_url || "null",
              country: entry.country || "null",
              demo_url: entry.playable_url || "null",
              description: entry.description || "null",
              github_username: entry.github_username || "null",
              heard_through: entry.heard_through || "null",
              hours: (entry.hours_spent_actual || entry.hours_spent)&.to_f&.round || "null",
              screenshot_url: entry.screenshot_url || "null",
              github_stars: entry.github_stars || 0
            }
          end
        end

        # Set HTTP caching headers for CDN/browser caching
        expires_in 10.minutes, public: true
        render json: entries
      end
    end
  end
end
