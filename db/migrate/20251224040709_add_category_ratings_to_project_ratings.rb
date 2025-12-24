class AddCategoryRatingsToProjectRatings < ActiveRecord::Migration[8.0]
  def change
    add_column :project_ratings, :originality, :integer, null: false, default: 3
    add_column :project_ratings, :technical, :integer, null: false, default: 3
    add_column :project_ratings, :usability, :integer, null: false, default: 3
    remove_column :project_ratings, :rating, :integer
  end
end
