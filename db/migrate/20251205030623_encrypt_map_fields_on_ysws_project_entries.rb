class EncryptMapFieldsOnYswsProjectEntries < ActiveRecord::Migration[8.0]
  def change
    remove_column :ysws_project_entries, :map_lat, :decimal
    remove_column :ysws_project_entries, :map_long, :decimal
    add_column :ysws_project_entries, :map_lat_ciphertext, :text
    add_column :ysws_project_entries, :map_long_ciphertext, :text
  end
end
