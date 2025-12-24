class AddRatingFieldsToYswsProjectEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :ysws_project_entries, :ratings_count, :integer, null: false, default: 0
    add_column :ysws_project_entries, :ratings_median, :decimal, precision: 3, scale: 2
    add_index :ysws_project_entries, [ :ratings_median, :ratings_count ]
  end
end
