class AddIndexesToYswsProjectEntries < ActiveRecord::Migration[8.0]
  def change
    add_index :ysws_project_entries, :approved_at
    add_index :ysws_project_entries, :ysws
    add_index :ysws_project_entries, :email
    add_index :ysws_project_entries, :country
    add_index :ysws_project_entries, :github_stars
    add_index :ysws_project_entries, :airtable_id, unique: true
  end
end
