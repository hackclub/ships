class CreateYswsProjectEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :ysws_project_entries do |t|
      t.string :airtable_id
      t.string :ysws
      t.string :email
      t.datetime :approved_at
      t.string :playable_url
      t.string :code_url
      t.text :description
      t.decimal :hours_spent
      t.decimal :hours_spent_actual
      t.string :archived_demo
      t.string :archived_repo
      t.decimal :map_lat
      t.decimal :map_long

      t.timestamps
    end
  end
end
