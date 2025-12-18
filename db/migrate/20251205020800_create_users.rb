class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :provider
      t.string :uid
      t.string :email
      t.string :name
      t.string :slack_id
      t.string :verification_status
      t.text :address
      t.boolean :admin

      t.timestamps
    end
  end
end
