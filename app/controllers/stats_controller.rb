class StatsController < ApplicationController
  # Displays global statistics for all YSWS project entries.
  # Uses fragment caching for expensive aggregations.
  def index
    stats = Rails.cache.fetch("stats/index", expires_in: 5.minutes) do
      entries = YswsProjectEntry.all

      {
        total_projects: entries.count,
        total_hours: entries.sum(:hours_spent).to_f.round,
        total_stars: entries.sum(:github_stars).to_i,
        viral_projects: entries.where("github_stars > 5").count,
        projects_by_country: YswsProjectEntry
          .group_by_normalized_country(entries)
          .first(15)
          .to_h,
        projects_by_ysws: entries
          .where.not(ysws: [ nil, "" ])
          .group(:ysws)
          .count
          .sort_by { |_, v| -v }
          .to_h,
        top_starred: entries
          .where.not(github_stars: nil)
          .order(github_stars: :desc)
          .limit(10)
          .to_a,
        recent_projects: entries
          .where.not(approved_at: nil)
          .order(approved_at: :desc)
          .limit(10)
          .to_a
      }
    end

    @total_projects = stats[:total_projects]
    @total_hours = stats[:total_hours]
    @total_stars = stats[:total_stars]
    @viral_projects = stats[:viral_projects]
    @projects_by_country = stats[:projects_by_country]
    @projects_by_ysws = stats[:projects_by_ysws]
    @top_starred = stats[:top_starred]
    @recent_projects = stats[:recent_projects]
  end
end
