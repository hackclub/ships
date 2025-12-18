class AddFieldsToYswsProjectEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :ysws_project_entries, :country, :string
    add_column :ysws_project_entries, :demo_url, :string
    add_column :ysws_project_entries, :github_username, :string
    add_column :ysws_project_entries, :heard_through, :string
  end
end
