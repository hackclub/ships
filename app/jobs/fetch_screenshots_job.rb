class FetchScreenshotsJob < ApplicationJob
  queue_as :default

  # Fetches screenshot URLs from Airtable for entries missing them.
  #
  # @param entry_ids [Array<Integer>] The IDs of entries to update.
  def perform(entry_ids = nil)
    entries = if entry_ids.present?
      YswsProjectEntry.where(id: entry_ids)
    else
      YswsProjectEntry.where(screenshot_url: [ nil, "" ])
    end

    airtable_ids = entries.pluck(:airtable_id).compact
    return if airtable_ids.empty?

    # Fetch records from Airtable by their IDs
    airtable_ids.each do |airtable_id|
      record = HackclubAirtable.find("Approved Projects", airtable_id)
      next unless record

      fields = record["fields"] || record
      screenshot = fields["Screenshot"]
      screenshot_url = screenshot.is_a?(Array) && screenshot.first ? screenshot.first["url"] : nil

      if screenshot_url.present?
        entry = entries.find_by(airtable_id: airtable_id)
        entry&.update_column(:screenshot_url, screenshot_url)
        Rails.logger.info "[FetchScreenshotsJob] Updated screenshot for #{airtable_id}"
      end
    rescue StandardError => e
      Rails.logger.error "[FetchScreenshotsJob] Failed to fetch #{airtable_id}: #{e.message}"
    end
  end
end
