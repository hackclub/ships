require 'csv'

CSV_PATH = Rails.root.join('db', 'seeds', 'airtable.csv')

puts "Loading YSWS project entries from #{CSV_PATH}..."
unless File.exist?(CSV_PATH)
  abort "CSV not found at #{CSV_PATH}. Place the exported CSV there and run again."
end

CSV.foreach(CSV_PATH, headers: true) do |row|
  raw = row.to_h

  # Hours fallback: override hours -> normal hours
  hours = raw["Override Hours Spent"].presence || raw["Hours Spent"].presence

  attrs = {
    airtable_id: raw["Record ID"] || raw["id"],
    ysws: raw["YSWS"] || raw["ysws"],
    email: raw["Email"] || raw["email"],
    approved_at: raw["Approved At"] || raw["approved_at"],
    playable_url: raw["Playable URL"] || raw["playable_url"],
    code_url: raw["Code URL"] || raw["code_url"],
    demo_url: raw["Demo URL"] || raw["demo_url"],
    description: raw["Description"] || raw["description"],
    hours_spent: hours,
    hours_spent_actual: raw["Override Hours Spent"] || raw["hours"],
    archived_demo: raw["Archive - Live URL"],
    archived_repo: raw["Archive - Code URL"],
    map_lat: raw["Geocoded - Latitude"],
    map_long: raw["Geocoded - Longitude"],
    country: raw["Country"] || raw["country"],
    github_username: raw["GitHub Username"] || raw["github_username"],
    heard_through: raw["Heard Through"] || raw["heard_through"]
  }

  # Convert empty strings and newline-only strings to nil
  attrs.transform_values! { |v| v.to_s.strip.empty? ? nil : v }

  airtable_id = attrs[:airtable_id]
  if airtable_id.nil?
    puts "Skipping row without airtable_id: #{raw.inspect}"
    next
  end

  entry = YswsProjectEntry.find_or_initialize_by(airtable_id: airtable_id)

  begin
    entry.assign_attributes(attrs.compact)
    entry.save!
    puts "Saved YswsProjectEntry airtable_id=#{entry.airtable_id} (#{entry.ysws})"
  rescue => e
    puts "Failed to save YswsProjectEntry airtable_id=#{airtable_id}: #{e.class} - #{e.message}"
  end
end

puts "Done seeding YSWS project entries."
