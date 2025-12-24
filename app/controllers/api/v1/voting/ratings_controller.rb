module Api
  module V1
    module Voting
      # Handles 3-category rating voting for projects.
      # Categories: Originality, Technical, Usability (each 1-5)
      # Final score = sum of all 3 categories (3-15 range)
      class RatingsController < ApplicationController
        before_action :require_login

        # POST /api/v1/voting/ratings
        # Creates or updates a user's rating for a project.
        def create
          project = YswsProjectEntry.find(params.require(:project_id))

          if project.email == current_user.email
            return render json: { error: "Cannot rate your own project" }, status: :unprocessable_entity
          end

          originality = params.require(:originality).to_i
          technical = params.require(:technical).to_i
          usability = params.require(:usability).to_i

          unless (1..5).cover?(originality) && (1..5).cover?(technical) && (1..5).cover?(usability)
            return render json: { error: "All ratings must be between 1 and 5" }, status: :unprocessable_entity
          end

          rating = ProjectRating.find_or_initialize_by(
            user: current_user,
            project: project
          )
          rating.originality = originality
          rating.technical = technical
          rating.usability = usability
          rating.save!

          render json: {
            project_id: project.id,
            originality: rating.originality,
            technical: rating.technical,
            usability: rating.usability,
            total_score: rating.total_score
          }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        # GET /api/v1/voting/ratings/:project_id
        # Returns the current user's rating for a project.
        def show
          project = YswsProjectEntry.find(params[:project_id])
          rating = ProjectRating.find_by(user: current_user, project: project)

          render json: {
            project_id: project.id,
            originality: rating&.originality,
            technical: rating&.technical,
            usability: rating&.usability,
            total_score: rating&.total_score,
            project_median: project.ratings_median&.to_f,
            project_count: project.ratings_count
          }
        end

        # GET /api/v1/voting/ratings/leaderboard
        # Returns projects ranked by median total score.
        def leaderboard
          min_ratings = params.fetch(:min_ratings, 3).to_i
          limit = params.fetch(:limit, 50).to_i.clamp(1, 200)

          projects = YswsProjectEntry
            .where("ratings_median IS NOT NULL AND ratings_count >= ?", min_ratings)
            .order(ratings_median: :desc, ratings_count: :desc)
            .limit(limit)

          render json: {
            projects: projects.map { |p| leaderboard_json(p) }
          }
        end

        private

        def leaderboard_json(project)
          {
            id: project.id,
            airtable_id: project.airtable_id,
            name: project.name,
            ysws: project.ysws,
            median_score: project.ratings_median&.to_f,
            ratings_count: project.ratings_count
          }
        end
      end
    end
  end
end
