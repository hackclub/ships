module Api
  module V1
    class YswsEntriesController < ApplicationController
      # GET /api/v1/ysws_entries
      # Returns all YSWS project entries as JSON, cached for 5 minutes.
      def index
        entries = Rails.cache.fetch("api/v1/ysws_entries", expires_in: 5.minutes) do
          YswsProjectEntry.where.not(ysws: "Boba Drops").map do |entry|
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
              screenshot_url: entry.screenshot_url || "null"
            }
          end
        end

        render json: entries
      end
    end
  end
end
