class YswsEntriesController < ApplicationController
  before_action :require_login

  # Fetches GitHub stars for a project entry.
  def fetch_stars
    entry = YswsProjectEntry.find(params[:id])

    unless entry.email == current_user.email
      head :forbidden
      return
    end

    stars = entry.fetch_github_stars!

    if stars
      redirect_to dash_path, notice: "Fetched #{stars} stars for #{entry.ysws}"
    else
      redirect_to dash_path, alert: "Could not fetch stars (not a valid GitHub repo?)"
    end
  end

  # Fetches virality stats from Airtable including linked mentions.
  # Cached for 1 hour to prevent rate limits.
  def fetch_virality
    entry = YswsProjectEntry.find(params[:id])

    unless entry.email == current_user.email
      head :forbidden
      return
    end

    cache_key = "virality_stats/#{entry.airtable_id}"
    @entry = entry

    # Allow manual cache refresh
    Rails.cache.delete(cache_key) if params[:refresh].present?

    cached_data = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      fetch_mentions_from_airtable(entry)
    end

    @mentions = cached_data[:mentions]
    @total_engagement = cached_data[:total_engagement]
    @cached_at = cached_data[:fetched_at]
  rescue => e
    # SECURITY: Log full error details but show generic message to user.
    Rails.logger.error "[YswsEntriesController#fetch_virality] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
    redirect_to dash_path, alert: "Failed to fetch virality stats. Please try again later."
  end

  private

  # Fetches mentions data from Airtable.
  # Uses a global cache for all mentions to avoid repeated full-table fetches.
  #
  # @param entry [YswsProjectEntry] The project entry.
  # @return [Hash] Hash containing mentions and total engagement.
  def fetch_mentions_from_airtable(entry)
    # Cache all mentions for 6 hours to avoid slow full-table fetches
    all_mentions = Rails.cache.fetch("airtable:all_mentions", expires_in: 6.hours) do
      HackclubAirtable.records("YSWS Project Mentions")
    end

    # Filter mentions that belong to this project
    found_mentions = all_mentions.select do |mention|
      fields = mention["fields"] || mention
      project_ref = fields["YSWS Approved Project"]
      project_ref.is_a?(Array) && project_ref.include?(entry.airtable_id)
    end

    # Extract relevant fields
    found_mentions = found_mentions.map do |mention|
      fields = mention["fields"] || mention
      {
        "Source" => fields["Source"],
        "Date" => fields["Date"],
        "Headline" => fields["Headline"],
        "URL" => fields["URL"],
        "Engagement Count" => fields["Engagement Count"],
        "Engagement Type" => fields["Engagement Type"]
      }
    end

    {
      mentions: found_mentions,
      total_engagement: found_mentions.sum { |m| m["Engagement Count"].to_i },
      fetched_at: Time.current
    }
  end
end
