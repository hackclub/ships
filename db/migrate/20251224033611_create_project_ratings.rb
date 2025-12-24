class CreateProjectRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :project_ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: { to_table: :ysws_project_entries }
      t.integer :originality, null: false
      t.integer :technical, null: false
      t.integer :usability, null: false

      t.timestamps
    end

    add_index :project_ratings, [ :user_id, :project_id ], unique: true
  end
end
