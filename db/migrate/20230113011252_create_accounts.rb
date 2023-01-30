class CreateAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :accounts do |t|
      t.string :signature
      t.string :private_key
      t.string :pin # For future use
      t.datetime :last_message_at
      t.timestamps
    end
  end
end
