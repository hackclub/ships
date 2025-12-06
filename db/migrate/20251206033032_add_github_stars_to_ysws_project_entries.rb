class AddGithubStarsToYswsProjectEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :ysws_project_entries, :github_stars, :integer
  end
end
