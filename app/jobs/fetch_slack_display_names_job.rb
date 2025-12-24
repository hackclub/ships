# Fetches Slack display names for users who have a slack_id but no display_name_from_slack.
# Uses the Slack users.info API to get the display name.
class FetchSlackDisplayNamesJob < ApplicationJob
  queue_as :default

  # Prevents duplicate jobs from running concurrently.
  def self.perform_later(*args)
    return if SolidQueue::Job.table_exists? && SolidQueue::Job.where(class_name: name, finished_at: nil).exists?
    super
  rescue ActiveRecord::StatementInvalid
    super
  end

  # Fetches display names for all users with slack_id but missing display_name_from_slack.
  def perform
    slack_token = Rails.application.credentials.dig(:slack, :bot_token)
    unless slack_token.present?
      Rails.logger.warn "[FetchSlackDisplayNamesJob] SLACK_BOT_TOKEN not configured, skipping"
      return
    end

    users_to_update = User
      .where.not(slack_id: [ nil, "" ])
      .where(display_name_from_slack: [ nil, "" ])

    Rails.logger.info "[FetchSlackDisplayNamesJob] Found #{users_to_update.count} users needing display names"

    updated = 0
    failed = 0

    users_to_update.find_each do |user|
      display_name = fetch_display_name(user.slack_id, slack_token)

      if display_name.present?
        user.update_column(:display_name_from_slack, display_name)
        updated += 1
        Rails.logger.info "[FetchSlackDisplayNamesJob] Updated #{user.email} -> #{display_name}"
      else
        failed += 1
      end

      sleep 0.1
    rescue StandardError => e
      failed += 1
      Rails.logger.error "[FetchSlackDisplayNamesJob] Failed for #{user.slack_id}: #{e.message}"
    end

    Rails.logger.info "[FetchSlackDisplayNamesJob] Complete. Updated: #{updated}, Failed: #{failed}"
  end

  private

  # Fetches display name from Slack API for a given user ID.
  #
  # @param slack_id [String] The Slack user ID.
  # @param slack_token [String] The Slack bot token.
  # @return [String, nil] The display name or nil if not found.
  def fetch_display_name(slack_id, slack_token)
    response = Faraday.get("https://slack.com/api/users.info") do |req|
      req.headers["Authorization"] = "Bearer #{slack_token}"
      req.params["user"] = slack_id
    end

    data = JSON.parse(response.body)

    unless data["ok"]
      Rails.logger.warn "[FetchSlackDisplayNamesJob] Slack API error for #{slack_id}: #{data['error']}"
      return nil
    end

    profile = data.dig("user", "profile") || {}
    profile["display_name"].presence || profile["real_name"].presence
  end
end
