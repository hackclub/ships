class CreateEloMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :elo_matches do |t|
      t.references :user, null: false, foreign_key: true
      t.references :winner_project, null: false, foreign_key: { to_table: :ysws_project_entries }
      t.references :loser_project, null: false, foreign_key: { to_table: :ysws_project_entries }

      t.float :winner_rating_before, null: false
      t.float :loser_rating_before, null: false
      t.float :winner_rating_after, null: false
      t.float :loser_rating_after, null: false

      t.timestamps
    end

    add_index :elo_matches,
              [ :user_id, :winner_project_id, :loser_project_id ],
              unique: true,
              name: "index_elo_matches_on_user_and_ordered_pair"
  end
end
