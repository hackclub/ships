module Api
  module V1
    # Provides global statistics for YSWS project entries.
    class StatsController < ApplicationController
      # GET /api/v1/stats
      # Returns aggregated statistics as JSON.
      def index
        entries = YswsProjectEntry.all

        stats = Rails.cache.fetch("api/v1/stats", expires_in: 5.minutes) do
          {
            total_projects: entries.count,
            total_hours: entries.sum(:hours_spent).to_f.round,
            total_stars: entries.sum(:github_stars).to_i,
            viral_projects: entries.where("github_stars > 5").count,
            projects_by_country: entries
              .where.not(country: [ nil, "" ])
              .group(:country)
              .count
              .sort_by { |_, v| -v }
              .first(15)
              .to_h,
            projects_by_ysws: entries
              .where.not(ysws: [ nil, "" ])
              .group(:ysws)
              .count
              .sort_by { |_, v| -v }
              .to_h,
            top_starred: entries
              .where.not(github_stars: nil)
              .order(github_stars: :desc)
              .limit(10)
              .map { |e| { ysws: e.ysws, code_url: e.code_url, stars: e.github_stars } },
            recent_projects: entries
              .where.not(approved_at: nil)
              .order(approved_at: :desc)
              .limit(10)
              .map { |e| { ysws: e.ysws, approved_at: e.approved_at&.iso8601 } }
          }
        end

        render json: stats
      end
    end
  end
end
