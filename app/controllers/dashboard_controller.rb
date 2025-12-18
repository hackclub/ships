class DashboardController < ApplicationController
  before_action :require_login

  def index
    @users_entries = YswsProjectEntry.where(email: current_user.email)

    # Queue job to fetch missing screenshots in the background
    entries_missing_screenshots = @users_entries.where(screenshot_url: [ nil, "" ])
    if entries_missing_screenshots.any?
      FetchScreenshotsJob.perform_later(entries_missing_screenshots.pluck(:id))
    end
  end
end
