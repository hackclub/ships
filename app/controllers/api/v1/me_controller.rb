module Api
  module V1
    class MeController < ApplicationController
     before_action :require_login

      def index
        users_projects = YswsProjectEntry.where(email: current_user.email)

        render json: users_projects.map { |entry|
          {
            id: entry.airtable_id,
            name: entry.name,
            ysws: entry.ysws,
            description: entry.description,
            code_url: entry.code_url,
            demo_url: entry.playable_url,
            screenshot_url: entry.screenshot_url,
            github_stars: entry.github_stars || 0,
            hours: (entry.hours_spent_actual || entry.hours_spent)&.to_f&.round,
            approved_at: entry.approved_at&.iso8601,
            country: entry.country
          }
        }
      end
    end
  end
end
