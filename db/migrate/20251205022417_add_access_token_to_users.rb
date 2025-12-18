class AddAccessTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :access_token_ciphertext, :text
  end
end
