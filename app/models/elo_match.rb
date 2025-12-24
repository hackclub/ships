# Represents a single ELO voting matchup between two projects.
# Records the winner, loser, and rating changes for audit purposes.
class EloMatch < ApplicationRecord
  belongs_to :user
  belongs_to :winner_project, class_name: "YswsProjectEntry"
  belongs_to :loser_project, class_name: "YswsProjectEntry"

  validates :winner_project_id, exclusion: {
    in: ->(match) { [ match.loser_project_id ] },
    message: "cannot be the same as loser project"
  }
  validates :winner_rating_before, :loser_rating_before,
            :winner_rating_after, :loser_rating_after, presence: true
end
