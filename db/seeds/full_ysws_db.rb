require 'csv'

CSV_PATH = Rails.root.join('db', 'seeds', 'airtable.csv')

puts "Loading YSWS project entries from #{CSV_PATH}..."
unless File.exist?(CSV_PATH)
  abort "CSV not found at #{CSV_PATH}. Place the exported CSV there and run again."
end

CSV.foreach(CSV_PATH, headers: true) do |row|
  raw = row.to_h

  attrs = {
    airtable_id: raw["Record ID"],
    ysws: raw["YSWS"],
    email: raw["Email"],
    approved_at: raw["Approved At"],
    playable_url: raw["Playable URL"],
    code_url: raw["Code URL"],
    description: raw["Description"],
    hours_spent: raw["Hours Spent"],
    hours_spent_actual: raw["Override Hours Spent"],
    archived_demo: raw["Archive - Live URL"],
    archived_repo: raw["Archive - Code URL"],
    map_lat: raw["Geocoded - Latitude"],
    map_long: raw["Geocoded - Longitude"]
  }

  # Convert empty strings to nil
  attrs.transform_values! { |v| v == '' ? nil : v }

  airtable_id = attrs[:airtable_id]
  if airtable_id.nil?
    puts "Skipping row without airtable_id: #{raw.inspect}"
    next
  end

  entry = YswsProjectEntry.find_or_initialize_by(airtable_id: airtable_id)

  begin
    entry.assign_attributes(attrs.compact)
    entry.save!
    puts "Saved YswsProjectEntry airtable_id=#{entry.airtable_id}"
  rescue => e
    puts "Failed to save YswsProjectEntry airtable_id=#{airtable_id}: #{e.class} - #{e.message}"
  end
end

puts "Done seeding YSWS project entries."
