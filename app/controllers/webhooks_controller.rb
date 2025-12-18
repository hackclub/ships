class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :airtable ]

  # POST /webhooks/airtable
  # Receives webhook events from Airtable when entries are created/updated.
  def airtable
    # Verify webhook secret if configured
    webhook_secret = ENV["AIRTABLE_WEBHOOK_SECRET"]
    if webhook_secret.present?
      provided_secret = request.headers["X-Airtable-Webhook-Secret"]
      unless ActiveSupport::SecurityUtils.secure_compare(webhook_secret, provided_secret.to_s)
        return render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end

    payload = JSON.parse(request.body.read)
    process_airtable_webhook(payload)

    render json: { status: "ok" }
  rescue JSON::ParserError
    render json: { error: "Invalid JSON" }, status: :bad_request
  end

  private

  # Processes an Airtable webhook payload and triggers appropriate events.
  #
  # @param payload [Hash] The Airtable webhook payload.
  def process_airtable_webhook(payload)
    # Airtable sends different payload formats depending on the trigger type
    records = payload["changedTablesById"]&.values&.flat_map { |t| t["createdRecordsById"]&.keys || [] } || []

    records.each do |record_id|
      entry = YswsProjectEntry.find_by(airtable_id: record_id)
      next unless entry

      # Determine event type based on entry state
      event_type = entry.approved_at.present? ? "entry.approved" : "entry.created"

      trigger_webhooks(event_type, entry)
    end

    # Also check for updates if that's what Airtable sent
    updated_records = payload["changedTablesById"]&.values&.flat_map { |t| t["changedRecordsById"]&.keys || [] } || []

    updated_records.each do |record_id|
      entry = YswsProjectEntry.find_by(airtable_id: record_id)
      next unless entry

      trigger_webhooks("entry.updated", entry)
    end
  end

  # Triggers all active webhook subscriptions for a given event.
  #
  # @param event_type [String] The type of event.
  # @param entry [YswsProjectEntry] The affected entry.
  def trigger_webhooks(event_type, entry)
    payload = {
      event_type: event_type,
      timestamp: Time.current.iso8601,
      entry: {
        id: entry.airtable_id,
        name: entry.name,
        ysws: entry.ysws,
        description: entry.description,
        code_url: entry.code_url,
        demo_url: entry.playable_url,
        country: entry.country,
        hours: entry.hours_spent&.to_f&.round,
        approved_at: entry.approved_at&.iso8601
      }
    }

    # Find subscriptions for the entry's user (by email)
    user = User.find_by(email: entry.email)

    if user
      subscriptions = user.webhook_subscriptions.active.for_event(event_type)
      subscriptions.each do |subscription|
        WebhookDeliveryJob.perform_later(subscription.id, payload)
      end
    end

    # Also trigger global/admin webhooks if configured
    admin_webhook_url = ENV["ADMIN_WEBHOOK_URL"]
    if admin_webhook_url.present?
      WebhookDeliveryJob.perform_later(nil, payload.merge(webhook_url: admin_webhook_url))
    end
  end
end
