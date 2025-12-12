class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  # Delivers a webhook payload to the subscription URL or Slack DM.
  #
  # @param subscription_id [Integer] The ID of the webhook subscription.
  # @param payload [Hash] The payload to deliver.
  def perform(subscription_id, payload)
    subscription = WebhookSubscription.find_by(id: subscription_id)
    return unless subscription&.active?

    if subscription.url.present?
      deliver_to_url(subscription.url, payload)
    end

    if subscription.slack_dm?
      deliver_slack_dm(subscription.user, payload)
    end
  end

  private

  # Delivers the payload to the webhook URL via HTTP POST.
  #
  # @param url [String] The webhook URL.
  # @param payload [Hash] The payload to deliver.
  def deliver_to_url(url, payload)
    response = Faraday.post(url) do |req|
      req.headers["Content-Type"] = "application/json"
      req.headers["User-Agent"] = "Ships-Webhook/1.0"
      req.body = payload.to_json
    end

    Rails.logger.info("Webhook delivered to #{url}: #{response.status}")
  rescue Faraday::Error => e
    Rails.logger.error("Webhook delivery failed to #{url}: #{e.message}")
  end

  # Sends a Slack DM to the user about the event.
  #
  # @param user [User] The user to notify.
  # @param payload [Hash] The event payload.
  def deliver_slack_dm(user, payload)
    return unless user.slack_id.present?

    slack_token = ENV["SLACK_BOT_TOKEN"]
    return unless slack_token.present?

    message = format_slack_message(payload)

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
      Rails.logger.info("Slack DM sent to #{user.slack_id}")
    else
      Rails.logger.error("Slack DM failed: #{result['error']}")
    end
  rescue Faraday::Error, JSON::ParserError => e
    Rails.logger.error("Slack DM delivery failed: #{e.message}")
  end

  # Formats the payload into a human-readable Slack message.
  #
  # @param payload [Hash] The event payload.
  # @return [String] The formatted message.
  def format_slack_message(payload)
    event = payload[:event_type] || payload["event_type"]
    entry = payload[:entry] || payload["entry"] || {}

    case event
    when "entry.created"
      "🚀 New project submitted: *#{entry['name'] || entry['ysws']}*\n#{entry['description']&.truncate(200)}"
    when "entry.approved"
      "✅ Your project *#{entry['name'] || entry['ysws']}* has been approved!"
    when "entry.updated"
      "📝 Project *#{entry['name'] || entry['ysws']}* was updated."
    else
      "📢 Event: #{event}\n#{entry.to_json}"
    end
  end
end
