class StatsController < ApplicationController
  # Displays global statistics for all YSWS project entries.
  def index
    entries = YswsProjectEntry.all

    @total_projects = entries.count
    @total_hours = entries.sum(:hours_spent).to_f.round
    @total_stars = entries.sum(:github_stars).to_i
    @viral_projects = entries.where("github_stars > 5").count

    @projects_by_country = entries
      .where.not(country: [ nil, "" ])
      .group(:country)
      .count
      .sort_by { |_, v| -v }
      .first(15)
      .to_h

    @projects_by_ysws = entries
      .where.not(ysws: [ nil, "" ])
      .group(:ysws)
      .count
      .sort_by { |_, v| -v }
      .to_h

    @top_starred = entries
      .where.not(github_stars: nil)
      .order(github_stars: :desc)
      .limit(10)

    @recent_projects = entries
      .where.not(approved_at: nil)
      .order(approved_at: :desc)
      .limit(10)
  end
end
