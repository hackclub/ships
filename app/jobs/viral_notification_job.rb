class ViralNotificationJob < ApplicationJob
  queue_as :default

  # Checks for projects with >5 stars that have mentions and notifies their owners.
  def perform
    slack_token = Rails.application.credentials.dig(:slack, :bot_token)
    unless slack_token.present?
      Rails.logger.warn "[ViralNotificationJob] SLACK_BOT_TOKEN not configured, skipping"
      return
    end

    # Find projects with >5 stars that haven't been notified yet
    # and belong to users who exist on the platform
    eligible_entries = YswsProjectEntry
      .where("github_stars > 5")
      .where(viral_notified: false)

    Rails.logger.info "[ViralNotificationJob] Found #{eligible_entries.count} eligible projects"

    eligible_entries.find_each do |entry|
      # Check if user exists on the platform
      user = User.find_by(email: entry.email)
      unless user
        Rails.logger.info "[ViralNotificationJob] User not on platform: #{entry.email}, skipping"
        next
      end

      # Fetch mentions from Airtable
      mentions_data = fetch_mentions(entry)

      if mentions_data[:mentions].any?
        notify_user(entry, user, mentions_data, slack_token)
      else
        Rails.logger.info "[ViralNotificationJob] No mentions for #{entry.name}, skipping notification"
      end

      # Mark as notified regardless (so we don't keep checking)
      entry.update_column(:viral_notified, true)
    rescue StandardError => e
      Rails.logger.error "[ViralNotificationJob] Failed for #{entry.airtable_id}: #{e.message}"
    end
  end

  private

  # Fetches project mentions from Airtable.
  #
  # @param entry [YswsProjectEntry] The project entry.
  # @return [Hash] Hash containing mentions array and total engagement.
  def fetch_mentions(entry)
    record = HackclubAirtable.find("Approved Projects", entry.airtable_id)
    return { mentions: [], total_engagement: 0 } unless record

    fields = record["fields"] || record
    search_ids = fields["YSWS Project Mentions - Searches"] || []
    return { mentions: [], total_engagement: 0 } if search_ids.empty?

    # Fetch all mentions directly from YSWS Project Mentions table
    all_mentions = HackclubAirtable.records("YSWS Project Mentions")

    # Filter mentions that belong to this project's searches
    found_mentions = all_mentions.select do |mention|
      mention_fields = mention["fields"] || mention
      project_ref = mention_fields["YSWS Approved Project"]
      project_ref.is_a?(Array) && project_ref.include?(entry.airtable_id)
    end

    # Extract relevant fields
    found_mentions = found_mentions.map do |mention|
      mention_fields = mention["fields"] || mention
      {
        "Source" => mention_fields["Source"],
        "Date" => mention_fields["Date"],
        "Headline" => mention_fields["Headline"],
        "URL" => mention_fields["URL"],
        "Engagement Count" => mention_fields["Engagement Count"]
      }
    end

    {
      mentions: found_mentions,
      total_engagement: found_mentions.sum { |m| m["Engagement Count"].to_i }
    }
  end

  # Sends a Slack DM to the project owner with their mentions.
  #
  # @param entry [YswsProjectEntry] The project entry.
  # @param user [User] The project owner.
  # @param mentions_data [Hash] The mentions data from Airtable.
  # @param slack_token [String] The Slack bot token.
  def notify_user(entry, user, mentions_data, slack_token)
    unless user.slack_id.present?
      Rails.logger.info "[ViralNotificationJob] No Slack ID for #{user.email}, skipping DM"
      return
    end

    message = build_message(entry, mentions_data)

    response = Faraday.post("https://slack.com/api/chat.postMessage") do |req|
      req.headers["Authorization"] = "Bearer #{slack_token}"
      req.headers["Content-Type"] = "application/json"
      req.body = {
        channel: user.slack_id,
        text: message,
        unfurl_links: false
      }.to_json
    end

    result = JSON.parse(response.body)
    if result["ok"]
      Rails.logger.info "[ViralNotificationJob] Notified #{user.email} about #{entry.name} mentions"
    else
      Rails.logger.error "[ViralNotificationJob] Slack error: #{result['error']}"
    end
  end

  # Builds a message with project mentions for the user.
  #
  # @param entry [YswsProjectEntry] The project entry.
  # @param mentions_data [Hash] The mentions data.
  # @return [String] The formatted Slack message.
  def build_message(entry, mentions_data)
    project_name = entry.name || entry.ysws || "Your project"
    mentions = mentions_data[:mentions]
    total_engagement = mentions_data[:total_engagement]

    lines = [
      "Hey! Your project *#{project_name}* has been getting some attention!",
      "",
      "⭐ *#{entry.github_stars} GitHub stars*",
      "📢 *#{mentions.count} mention#{mentions.count == 1 ? '' : 's'}* found online",
      total_engagement > 0 ? "💬 *#{total_engagement} total engagement*" : nil,
      ""
    ].compact

    # Add up to 15 mention previews
    mentions.first(15).each do |mention|
      source = mention["Source"] || "Unknown"
      headline = mention["Headline"]&.truncate(60) || "No headline"
      url = mention["URL"]

      if url.present?
        lines << "• *#{source}*: #{headline}\n  #{url}"
      else
        lines << "• *#{source}*: #{headline}"
      end
    end

    if mentions.count > 5
      lines << ""
      lines << "_...and #{mentions.count - 5} more mention#{mentions.count - 5 == 1 ? '' : 's'}_"
    end

    lines << ""
    lines << "Check out all your stats at #{ENV.fetch('APP_URL', 'https://ships.hackclub.com')}/dash "

    lines.join("\n")
  end
end
