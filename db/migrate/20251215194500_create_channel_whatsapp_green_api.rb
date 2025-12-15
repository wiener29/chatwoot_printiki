class CreateChannelWhatsappGreenApi < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_whatsapp_green_api do |t|
      t.integer :account_id, null: false
      t.string :id_instance, null: false
      t.string :api_token_instance, null: false
      t.string :phone_number
      t.timestamps
      
      t.index :id_instance, unique: true
      t.index :phone_number
    end
  end
end
