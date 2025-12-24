class AddEloFieldsToYswsProjectEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :ysws_project_entries, :elo_rating, :float, null: false, default: 1500.0
    add_column :ysws_project_entries, :elo_matches_count, :integer, null: false, default: 0
    add_index :ysws_project_entries, :elo_rating
  end
end
