# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_02_06_171713) do
  create_table "accounts", force: :cascade do |t|
    t.string "signature"
    t.string "private_key"
    t.string "pin"
    t.datetime "last_message_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.integer "account_id"
    t.string "sms_payload"
    t.string "provider_message_code", null: false
    t.string "signature"
    t.text "content", null: false
    t.string "event"
    t.datetime "submited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_messages_on_account_id"
    t.index ["provider_message_code"], name: "index_messages_on_provider_message_code", unique: true
  end

  add_foreign_key "messages", "accounts"
end
