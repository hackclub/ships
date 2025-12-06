class DashboardController < ApplicationController
  before_action :require_login

  def index
    @users_entries = YswsProjectEntry.where(email: current_user.email)

    # Auto-fetch GitHub stars for entries that don't have them yet
    @users_entries.each do |entry|
      if entry.github_repo_path.present? && entry.github_stars.nil?
        entry.fetch_github_stars!
      end
    end
  end
end
