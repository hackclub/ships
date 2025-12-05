class AddDisplayNameFromSlackToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :display_name_from_slack, :string
  end
end
