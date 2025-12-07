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
  #
  # @param entry [YswsProjectEntry] The project entry.
  # @return [Hash] Hash containing mentions and total engagement.
  def fetch_mentions_from_airtable(entry)
    api_key = Rails.application.credentials.dig(:airtable, :api_key)
    base_id = Rails.application.credentials.dig(:airtable, :base_id)

    table = Norairrecord.table(api_key, base_id, "Approved Projects")
    record = table.find(entry.airtable_id)
    search_ids = record.fields["YSWS Project Mentions - Searches"] || []

    return { mentions: [], total_engagement: 0, fetched_at: Time.current } if search_ids.empty?

    searches_table = Norairrecord.table(api_key, base_id, "YSWS Project Mentions")
    mentions_table = Norairrecord.table(api_key, base_id, "YSWS Project Mention Searches")

    # Collect all mention IDs first to batch fetch
    all_mention_ids = []
    search_ids.each do |search_id|
      search_record = searches_table.find(search_id)
      all_mention_ids.concat(search_record.fields["Found Project Mentions"] || [])
    rescue => e
      Rails.logger.error "[YswsEntriesController] Failed to fetch search #{search_id}: #{e.message}"
    end

    # Fetch all mentions (Airtable doesn't support batch get, but we cache the result)
    found_mentions = []
    all_mention_ids.uniq.each do |mention_id|
      mention_record = mentions_table.find(mention_id)
      fields = mention_record.fields.slice(
        "Source",
        "Date",
        "Headline",
        "URL",
        "Engagement Count",
        "Engagement Type",
        "Mentions Hack Club?",
        "Archive URL"
      )
      found_mentions << fields
    rescue => e
      Rails.logger.error "[YswsEntriesController] Failed to fetch mention #{mention_id}: #{e.message}"
    end

    {
      mentions: found_mentions,
      total_engagement: found_mentions.sum { |m| m["Engagement Count"].to_i },
      fetched_at: Time.current
    }
  end
end
