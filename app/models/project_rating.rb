# Represents a user's rating of a project across 3 categories.
# One rating per user per project, can be updated.
# Final score = originality + technical + usability (3-15 range)
class ProjectRating < ApplicationRecord
  belongs_to :user
  belongs_to :project, class_name: "YswsProjectEntry"

  validates :originality, :technical, :usability,
            inclusion: { in: 1..5, message: "must be between 1 and 5" }
  validates :user_id, uniqueness: { scope: :project_id, message: "has already rated this project" }

  after_commit :update_project_rating_stats, on: [ :create, :update, :destroy ]

  # Returns the total score (sum of all 3 categories).
  #
  # @return [Integer] Total score from 3 to 15.
  def total_score
    originality + technical + usability
  end

  private

  # Queues a background job to recalculate the project's median rating.
  def update_project_rating_stats
    RatingStatsJob.perform_later(project_id)
  end
end
