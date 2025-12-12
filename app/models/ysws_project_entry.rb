class YswsProjectEntry < ApplicationRecord
  has_encrypted :map_lat
  has_encrypted :map_long

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

  # Fetches and caches the star count from GitHub API.
  #
  # @return [Integer, nil] The star count or nil if fetch fails.
  def fetch_github_stars!
    repo_path = github_repo_path
    return nil unless repo_path

    response = Faraday.get("https://api.github.com/repos/#{repo_path}") do |req|
      req.headers["Accept"] = "application/vnd.github.v3+json"
      req.headers["User-Agent"] = "Ships-App"
    end

    return nil unless response.success?

    data = JSON.parse(response.body)
    stars = data["stargazers_count"]
    update_column(:github_stars, stars)
    stars
  rescue Faraday::Error, JSON::ParserError
    nil
  end

  # Checks if the project has more than 5 stars.
  #
  # @return [Boolean] True if stars > 5.
  def viral?
    github_stars.present? && github_stars > 5
  end
end
