class AddScreenshotUrlToYswsProjectEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :ysws_project_entries, :screenshot_url, :string
  end
end
