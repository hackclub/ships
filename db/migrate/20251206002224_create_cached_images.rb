class CreateCachedImages < ActiveRecord::Migration[8.0]
  def change
    create_table :cached_images do |t|
      t.string :airtable_id, null: false
      t.string :original_url
      t.datetime :expires_at

      t.timestamps
    end
    add_index :cached_images, :airtable_id, unique: true
  end
end
