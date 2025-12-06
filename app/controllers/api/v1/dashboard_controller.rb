module Api
  module V1
    # Provides dashboard data for the current user's YSWS entries.
    class DashboardController < ApplicationController
      before_action :require_login

      # GET /api/v1/dashboard
      # Returns the current user's project entries as JSON.
      def index
        entries = YswsProjectEntry.where(email: current_user.email)

        render json: {
          user: {
            email: current_user.email,
            name: current_user.display_name
          },
          entries: entries.map do |entry|
            {
              id: entry.id,
              airtable_id: entry.airtable_id,
              ysws: entry.ysws,
              description: entry.description,
              hours_spent: entry.hours_spent&.to_f,
              country: entry.country,
              approved_at: entry.approved_at&.iso8601,
              demo_url: entry.demo_url,
              code_url: entry.code_url,
              github_stars: entry.github_stars,
              viral: entry.viral?
            }
          end
        }
      end
    end
  end
end
