class CreateWebhookSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :webhook_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :url
      t.boolean :active, default: true, null: false
      t.boolean :slack_dm, default: false, null: false

      t.timestamps
    end

    add_index :webhook_subscriptions, [ :user_id, :event_type ]
  end
end
