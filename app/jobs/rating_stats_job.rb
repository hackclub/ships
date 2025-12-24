# Recalculates the median rating for a project after a rating change.
# The score is the sum of (originality + technical + usability) per voter,
# and we take the median of all those sums.
class RatingStatsJob < ApplicationJob
  queue_as :default

  # Recalculates rating stats for a project.
  #
  # @param project_id [Integer] The ID of the project to update.
  def perform(project_id)
    project = YswsProjectEntry.find_by(id: project_id)
    return unless project

    ratings = ProjectRating.where(project_id: project.id)
    count = ratings.count

    if count.positive?
      # Calculate median of total scores (originality + technical + usability)
      scores = ratings.pluck(Arel.sql("originality + technical + usability")).sort
      median = if scores.length.odd?
                 scores[scores.length / 2]
      else
                 (scores[(scores.length / 2) - 1] + scores[scores.length / 2]) / 2.0
      end
    else
      median = nil
    end

    project.update!(
      ratings_count: count,
      ratings_median: median
    )

    Rails.logger.info "[RatingStatsJob] Updated #{project.id}: count=#{count}, median=#{median}"
  rescue StandardError => e
    Rails.logger.error "[RatingStatsJob] Failed for project #{project_id}: #{e.message}"
  end
end
