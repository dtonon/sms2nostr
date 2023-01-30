class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.references :account, null: true, foreign_key: true
      t.string :sms_payload
      t.string :provider_message_code, null: false
      t.string :signature # For future use
      t.text :content, null: false
      t.string :event
      t.datetime :submited_at
      t.timestamps
    end
  end
end
