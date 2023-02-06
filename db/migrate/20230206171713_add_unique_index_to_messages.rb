class AddUniqueIndexToMessages < ActiveRecord::Migration[7.0]
  def change
    add_index :messages, :provider_message_code, unique: true
  end
end
