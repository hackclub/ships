class BackfillApiKeysForExistingUsers < ActiveRecord::Migration[8.0]
  def up
    User.where(api_key: nil).find_each do |user|
      user.update_column(:api_key, SecureRandom.hex(32))
    end
  end

  def down
    # No-op: we don't want to remove API keys on rollback
  end
end
