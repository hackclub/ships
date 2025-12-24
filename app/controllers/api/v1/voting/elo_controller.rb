module Api
  module V1
    module Voting
      # Handles ELO-based voting where users compare two projects.
      class EloController < ApplicationController
        before_action :require_login

        # GET /api/v1/voting/elo/matchup
        # Returns two random projects for the user to compare.
        def matchup
          projects = YswsProjectEntry
            .where.not(ysws: "Boba Drops")
            .where.not(email: current_user.email)
            .where("elo_matches_count < ?", 100)
            .order(Arel.sql("RANDOM()"))
            .limit(2)

          if projects.size < 2
            return render json: { error: "Not enough projects available" }, status: :unprocessable_entity
          end

          render json: {
            projects: projects.map { |p| project_json(p) }
          }
        end

        # POST /api/v1/voting/elo/vote
        # Records a vote where winner_id beats loser_id.
        def vote
          winner = YswsProjectEntry.find(params.require(:winner_id))
          loser = YswsProjectEntry.find(params.require(:loser_id))

          if winner.id == loser.id
            return render json: { error: "Projects must be different" }, status: :unprocessable_entity
          end

          if EloMatch.exists?(user: current_user, winner_project_id: winner.id, loser_project_id: loser.id)
            return render json: { error: "You already voted on this matchup" }, status: :unprocessable_entity
          end

          match = EloMatchService.call(winner: winner, loser: loser, user: current_user)

          render json: {
            match: {
              winner_rating: match.winner_rating_after.round(1),
              loser_rating: match.loser_rating_after.round(1)
            }
          }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        # GET /api/v1/voting/elo/leaderboard
        # Returns projects ranked by ELO rating.
        def leaderboard
          min_matches = params.fetch(:min_matches, 5).to_i
          limit = params.fetch(:limit, 50).to_i.clamp(1, 200)

          projects = YswsProjectEntry
            .where("elo_matches_count >= ?", min_matches)
            .order(elo_rating: :desc)
            .limit(limit)

          render json: {
            projects: projects.map { |p| leaderboard_json(p) }
          }
        end

        private

        def project_json(project)
          {
            id: project.id,
            airtable_id: project.airtable_id,
            name: project.name,
            ysws: project.ysws,
            description: project.description,
            screenshot_url: project.screenshot_url,
            demo_url: project.playable_url,
            code_url: project.code_url
          }
        end

        def leaderboard_json(project)
          {
            id: project.id,
            airtable_id: project.airtable_id,
            name: project.name,
            ysws: project.ysws,
            elo_rating: project.elo_rating.round(1),
            matches_count: project.elo_matches_count
          }
        end
      end
    end
  end
end
