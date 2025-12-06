module Api
  module V1
    module Admin
      # Admin-only API endpoints for managing users and entries.
      class AdminController < Api::V1::ApplicationController
        before_action :require_admin

        # GET /api/v1/admin/users
        # Returns all users.
        def users
          users = User.order(:email).map do |user|
            {
              id: user.id,
              email: user.email,
              name: user.name,
              display_name: user.display_name,
              slack_id: user.slack_id,
              admin: user.admin?,
              verification_status: user.verification_status,
              created_at: user.created_at&.iso8601
            }
          end

          render json: { total: users.size, users: users }
        end

        # GET /api/v1/admin/entries
        # Returns all YSWS project entries.
        def entries
          entries = YswsProjectEntry.order(approved_at: :desc).map do |entry|
            {
              id: entry.id,
              airtable_id: entry.airtable_id,
              ysws: entry.ysws,
              email: entry.email,
              description: entry.description,
              hours_spent: entry.hours_spent&.to_f,
              hours_spent_actual: entry.hours_spent_actual&.to_f,
              country: entry.country,
              approved_at: entry.approved_at&.iso8601,
              demo_url: entry.demo_url,
              playable_url: entry.playable_url,
              code_url: entry.code_url,
              github_username: entry.github_username,
              github_stars: entry.github_stars,
              heard_through: entry.heard_through,
              created_at: entry.created_at&.iso8601
            }
          end

          render json: { total: entries.size, entries: entries }
        end

        # GET /api/v1/admin/stats
        # Returns admin-specific statistics.
        def stats
          render json: {
            users: {
              total: User.count,
              admins: User.where(admin: true).count,
              verified: User.where(verification_status: "verified").count,
              with_slack: User.where.not(slack_id: [ nil, "" ]).count
            },
            entries: {
              total: YswsProjectEntry.count,
              approved: YswsProjectEntry.where.not(approved_at: nil).count,
              pending: YswsProjectEntry.where(approved_at: nil).count,
              viral: YswsProjectEntry.where("github_stars > 5").count,
              total_hours: YswsProjectEntry.sum(:hours_spent).to_f.round(1),
              total_stars: YswsProjectEntry.sum(:github_stars).to_i
            },
            by_ysws: YswsProjectEntry
              .where.not(ysws: [ nil, "" ])
              .group(:ysws)
              .count
              .sort_by { |_, v| -v }
              .to_h,
            by_country: YswsProjectEntry
              .where.not(country: [ nil, "" ])
              .group(:country)
              .count
              .sort_by { |_, v| -v }
              .to_h,
            recent_users: User.order(created_at: :desc).limit(10).map do |u|
              { email: u.email, created_at: u.created_at&.iso8601 }
            end
          }
        end

        private

        # Ensures the user is an admin.
        def require_admin
          unless current_user&.admin?
            render json: { error: "Forbidden" }, status: :forbidden
          end
        end
      end
    end
  end
end
