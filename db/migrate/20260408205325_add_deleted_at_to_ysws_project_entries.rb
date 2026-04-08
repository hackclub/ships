class AddDeletedAtToYswsProjectEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :ysws_project_entries, :deleted_at, :datetime
    add_index :ysws_project_entries, :deleted_at
  end
end
