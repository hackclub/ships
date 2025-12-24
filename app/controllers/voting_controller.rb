# Frontend controller for voting UI pages.
class VotingController < ApplicationController
  before_action :require_login

  # GET /vote - ELO voting page (compare two projects)
  def index
    load_matchup
  end

  # GET /vote/rate - Category rating page (rate one project at a time)
  def rate
    @project = YswsProjectEntry
      .where.not(ysws: "Boba Drops")
      .where.not(email: current_user.email)
      .order(Arel.sql("RANDOM()"))
      .first

    @existing_rating = ProjectRating.find_by(user: current_user, project: @project) if @project
  end

  # GET /vote/leaderboard - Combined leaderboards page
  def leaderboard
    @min_elo_matches = params.fetch(:min_elo_matches, 5).to_i
    @min_ratings = params.fetch(:min_ratings, 3).to_i
    @limit = params.fetch(:limit, 25).to_i.clamp(1, 100)

    @elo_leaders = YswsProjectEntry
      .where("elo_matches_count >= ?", @min_elo_matches)
      .order(elo_rating: :desc)
      .limit(@limit)

    @rating_leaders = YswsProjectEntry
      .where("ratings_median IS NOT NULL AND ratings_count >= ?", @min_ratings)
      .order(ratings_median: :desc, ratings_count: :desc)
      .limit(@limit)
  end

  private

  def load_matchup
    @projects = YswsProjectEntry
      .where.not(ysws: "Boba Drops")
      .where.not(email: current_user.email)
      .order(Arel.sql("RANDOM()"))
      .limit(2)
  end
end
