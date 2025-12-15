class CreateChannelVk < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_vk do |t|
      t.integer :account_id, null: false
      t.string :group_id, null: false
      t.string :access_token, null: false
      t.string :confirmation_token, null: false
      t.string :secret_key
      t.timestamps
      
      t.index :group_id, unique: true
    end
  end
end
