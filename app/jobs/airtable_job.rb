class AirtableJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 100
  SLOW_INTERVAL = 12.hours
  CACHE_KEY = "airtable_job:last_run"

  # Prevents duplicate jobs from running concurrently.
  def self.perform_later(*args)
    return if SolidQueue::Job.where(class_name: name, finished_at: nil).exists?
    super
  end

  # Syncs approved projects from Airtable to the database.
  def perform
    if should_skip_run?
      Rails.logger.info "[AirtableJob] Skipping sync (slow_down_sync_job enabled, last run was < #{SLOW_INTERVAL.inspect} ago)"
      return
    end

    Rails.logger.info "[AirtableJob] Starting sync..."

    table = Norairrecord.table(
      Rails.application.credentials.dig(:airtable, :api_key),
      Rails.application.credentials.dig(:airtable, :base_id),
      "Approved Projects"
    )

    created = 0
    updated = 0
    failed = 0
    batch_count = 0

    # Fetch all records and process in batches
    all_records = table.records

    # DEV ONLY: Filter to specific email for testing
    if Rails.env.development?
      all_records = all_records.select { |r| r.fields["Email"] == "neon@saahild.com" }
    end

    Rails.logger.info "[AirtableJob] Fetched #{all_records.size} records from Airtable"
    
    all_records.each_slice(BATCH_SIZE) do |batch|
      batch_count += 1
      Rails.logger.info "[AirtableJob] Processing batch #{batch_count} (#{batch.size} records)"

      batch.each do |record|
        attrs = map_record_to_attrs(record)
        next if attrs[:airtable_id].blank?

        entry = YswsProjectEntry.find_or_initialize_by(airtable_id: attrs[:airtable_id])
        is_new = entry.new_record?

        if entry.update(attrs)
          if is_new
            created += 1
            Rails.logger.info "[AirtableJob] Created new entry: #{attrs[:airtable_id]}"
          else
            updated += 1
          end
        else
          failed += 1
          Rails.logger.error "[AirtableJob] Failed to save #{attrs[:airtable_id]}: #{entry.errors.full_messages.join(', ')}"
        end
      rescue ArgumentError => e
        failed += 1
        Rails.logger.error "[AirtableJob] Error processing #{attrs[:airtable_id]}: #{e.message}"
      end
    end

    # Invalidate cache after sync
    Rails.cache.delete("api/v1/ysws_entries")

    # Record successful run time for slow mode check
    Rails.cache.write(CACHE_KEY, Time.current)

    Rails.logger.info "[AirtableJob] Sync complete. Created: #{created}, Updated: #{updated}, Failed: #{failed}"
  end

  private

  # Checks if we should skip this run based on slow_down_sync_job flag.
  #
  # @return [Boolean] True if the flag is enabled and last run was < 12 hours ago.
  def should_skip_run?
    return false unless Flipper.enabled?(:slow_down_sync_job)

    last_run = Rails.cache.read(CACHE_KEY)
    return false if last_run.nil?

    Time.current - last_run < SLOW_INTERVAL
  end

  # Maps an Airtable record to model attributes.
  #
  # @param record [Norairrecord::Record] The Airtable record.
  # @return [Hash] Attributes hash for YswsProjectEntry.
  def map_record_to_attrs(record)
    fields = record.fields

    hours = presence(fields["Override Hours Spent"]) || presence(fields["Hours Spent"])

    # Extract screenshot URL from Airtable attachment field
    # screenshot = fields["Screenshot"]
    # screenshot_url = screenshot.is_a?(Array) && screenshot.first ? screenshot.first["url"] : nil

    # YSWS Name comes as an array from Airtable lookup, extract first value
    ysws_name = fields["YSWS Name - Lookup"]
    ysws_name = ysws_name.first if ysws_name.is_a?(Array)

    attrs = {
      airtable_id: record.id,
      ysws: ysws_name,
      email: fields["Email"],
      approved_at: fields["Approved At"],
      playable_url: fields["Playable URL"],
      code_url: fields["Code URL"],
      description: presence(fields["Description"]),
      hours_spent: hours,
      hours_spent_actual: fields["Override Hours Spent"],
      archived_demo: fields["Archive - Live URL"],
      archived_repo: fields["Archive - Code URL"],
      map_lat: fields["Geocoded - Latitude"],
      map_long: fields["Geocoded - Longitude"],
      country: fields["Country"],
      github_username: fields["GitHub Username"],
      heard_through: fields["Heard Through"]
      # screenshot_url: screenshot_url
    }

    # Sanitize all string values to remove null bytes
    attrs.transform_values { |v| sanitize_string(v) }.compact
  end

  # Returns nil for blank strings and sanitizes null bytes.
  #
  # @param value [String, nil] The value to check.
  # @return [String, nil] The value or nil if blank.
  def presence(value)
    sanitize_string(value.to_s.strip).presence
  end

  # Removes null bytes from strings (PostgreSQL doesn't allow them).
  #
  # @param value [String, nil] The value to sanitize.
  # @return [String, nil] The sanitized value.
  def sanitize_string(value)
    return value unless value.is_a?(String)

    value.delete("\x00")
  end
end
