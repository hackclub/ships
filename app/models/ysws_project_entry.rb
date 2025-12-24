class YswsProjectEntry < ApplicationRecord
  include CountryNormalizer

  has_encrypted :map_lat
  has_encrypted :map_long

  has_many :elo_matches_as_winner, class_name: "EloMatch", foreign_key: :winner_project_id, dependent: :destroy
  has_many :elo_matches_as_loser, class_name: "EloMatch", foreign_key: :loser_project_id, dependent: :destroy
  has_many :project_ratings, foreign_key: :project_id, dependent: :destroy

  # Extracts owner/repo from a GitHub URL.
  #
  # @return [String, nil] The owner/repo string or nil if not a valid GitHub URL.
  def github_repo_path
    return nil unless code_url.present?

    match = code_url.match(%r{github\.com/([^/]+/[^/]+)})
    match ? match[1].gsub(/\.git$/, "") : nil
  end
  # Extracts the repository name from the GitHub URL.
  #
  # @return [String, nil] The repository name or nil if not a valid GitHub URL.
  def name
    return nil unless code_url.present?

    match = code_url.match(%r{github\.com/[^/]+/([^/?#]+)})
    match ? match[1].gsub(/\.git$/, "") : nil
  end

  # Checks if the project has more than 5 stars.
  #
  # @return [Boolean] True if stars > 5.
  def viral?
    github_stars.present? && github_stars > 5
  end
end
