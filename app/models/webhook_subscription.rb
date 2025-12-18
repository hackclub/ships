class WebhookSubscription < ApplicationRecord
  belongs_to :user

  # Valid event types for webhook subscriptions.
  EVENT_TYPES = %w[entry.created entry.updated entry.approved].freeze

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
  validates :url, presence: true, unless: :slack_dm?
  validate :must_have_url_or_slack_dm

  scope :active, -> { where(active: true) }
  scope :for_event, ->(event) { where(event_type: event) }

  private

  # Ensures either url or slack_dm is set for the subscription.
  def must_have_url_or_slack_dm
    return if url.present? || slack_dm?

    errors.add(:base, "Either URL or Slack DM must be enabled")
  end
end
