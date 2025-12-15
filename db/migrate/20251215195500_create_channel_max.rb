class CreateChannelMax < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_max do |t|
      t.integer :account_id, null: false
      t.string :instance_id, null: false # Assuming similar structure
      t.string :api_token, null: false
      t.timestamps
      
      t.index :instance_id, unique: true
    end
  end
end
