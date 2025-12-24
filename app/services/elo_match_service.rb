# Service for processing ELO voting matchups.
# Calculates new ratings using standard ELO formula and records the match.
class EloMatchService
  K_FACTOR = 32

  # Processes a vote where winner beats loser.
  #
  # @param winner [YswsProjectEntry] The project chosen as winner.
  # @param loser [YswsProjectEntry] The project that lost.
  # @param user [User] The user casting the vote.
  # @return [EloMatch] The created match record.
  # @raise [ActiveRecord::RecordInvalid] If validation fails.
  def self.call(winner:, loser:, user:)
    new(winner: winner, loser: loser, user: user).call
  end

  def initialize(winner:, loser:, user:)
    @winner = winner
    @loser = loser
    @user = user
  end

  def call
    ActiveRecord::Base.transaction do
      @winner.lock!
      @loser.lock!

      winner_before = @winner.elo_rating
      loser_before = @loser.elo_rating

      expected_winner = expected_score(winner_before, loser_before)
      expected_loser = 1.0 - expected_winner

      winner_after = winner_before + K_FACTOR * (1.0 - expected_winner)
      loser_after = loser_before + K_FACTOR * (0.0 - expected_loser)

      @winner.update!(
        elo_rating: winner_after,
        elo_matches_count: @winner.elo_matches_count + 1
      )
      @loser.update!(
        elo_rating: loser_after,
        elo_matches_count: @loser.elo_matches_count + 1
      )

      EloMatch.create!(
        user: @user,
        winner_project: @winner,
        loser_project: @loser,
        winner_rating_before: winner_before,
        loser_rating_before: loser_before,
        winner_rating_after: winner_after,
        loser_rating_after: loser_after
      )
    end
  end

  private

  # Calculates expected score using ELO formula.
  #
  # @param rating_a [Float] Rating of player A.
  # @param rating_b [Float] Rating of player B.
  # @return [Float] Expected score for player A (0.0 to 1.0).
  def expected_score(rating_a, rating_b)
    1.0 / (1.0 + (10.0**((rating_b - rating_a) / 400.0)))
  end
end
