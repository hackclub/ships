class AddViralNotifiedToYswsProjectEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :ysws_project_entries, :viral_notified, :boolean, default: false, null: false
  end
end
