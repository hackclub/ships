class DashboardController < ApplicationController
  before_action :require_login

  def index
    @users_entries = YswsProjectEntry.where(email: current_user.email)
  end
end
