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

ActiveRecord::Schema[8.0].define(version: 2025_12_06_011017) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audits1984_audits", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.bigint "session_id", null: false
    t.bigint "auditor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auditor_id"], name: "index_audits1984_audits_on_auditor_id"
    t.index ["session_id"], name: "index_audits1984_audits_on_session_id"
  end

  create_table "cached_images", force: :cascade do |t|
    t.string "airtable_id", null: false
    t.string "original_url"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["airtable_id"], name: "index_cached_images_on_airtable_id", unique: true
  end

  create_table "console1984_commands", force: :cascade do |t|
    t.text "statements"
    t.bigint "sensitive_access_id"
    t.bigint "session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sensitive_access_id"], name: "index_console1984_commands_on_sensitive_access_id"
    t.index ["session_id", "created_at", "sensitive_access_id"], name: "on_session_and_sensitive_chronologically"
  end

  create_table "console1984_sensitive_accesses", force: :cascade do |t|
    t.text "justification"
    t.bigint "session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_console1984_sensitive_accesses_on_session_id"
  end

  create_table "console1984_sessions", force: :cascade do |t|
    t.text "reason"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_console1984_sessions_on_created_at"
    t.index ["user_id", "created_at"], name: "index_console1984_sessions_on_user_id_and_created_at"
  end

  create_table "console1984_users", force: :cascade do |t|
    t.string "username", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_console1984_users_on_username"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "email"
    t.string "name"
    t.string "slack_id"
    t.string "verification_status"
    t.text "address"
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "access_token_ciphertext"
    t.string "display_name_from_slack"
    t.string "first_name"
    t.string "last_name"
  end

  create_table "ysws_project_entries", force: :cascade do |t|
    t.string "airtable_id"
    t.string "ysws"
    t.string "email"
    t.datetime "approved_at"
    t.string "playable_url"
    t.string "code_url"
    t.text "description"
    t.decimal "hours_spent"
    t.decimal "hours_spent_actual"
    t.string "archived_demo"
    t.string "archived_repo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "map_lat_ciphertext"
    t.text "map_long_ciphertext"
    t.string "country"
    t.string "demo_url"
    t.string "github_username"
    t.string "heard_through"
    t.string "screenshot_url"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
