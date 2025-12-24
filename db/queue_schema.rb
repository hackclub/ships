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

ActiveRecord::Schema[8.1].define(version: 2025_12_24_040709) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audits1984_audits", force: :cascade do |t|
    t.bigint "auditor_id", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "session_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["auditor_id"], name: "index_audits1984_audits_on_auditor_id"
    t.index ["session_id"], name: "index_audits1984_audits_on_session_id"
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.datetime "created_at"
    t.string "data_source"
    t.bigint "query_id"
    t.text "statement"
    t.bigint "user_id"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.string "check_type"
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "emails"
    t.datetime "last_run_at"
    t.text "message"
    t.bigint "query_id"
    t.string "schedule"
    t.text "slack_channels"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dashboard_id"
    t.integer "position"
    t.bigint "query_id"
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.string "data_source"
    t.text "description"
    t.string "name"
    t.text "statement"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "cached_images", force: :cascade do |t|
    t.string "airtable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "original_url"
    t.datetime "updated_at", null: false
    t.index ["airtable_id"], name: "index_cached_images_on_airtable_id", unique: true
  end

  create_table "console1984_commands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "sensitive_access_id"
    t.bigint "session_id", null: false
    t.text "statements"
    t.datetime "updated_at", null: false
    t.index ["sensitive_access_id"], name: "index_console1984_commands_on_sensitive_access_id"
    t.index ["session_id", "created_at", "sensitive_access_id"], name: "on_session_and_sensitive_chronologically"
  end

  create_table "console1984_sensitive_accesses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "justification"
    t.bigint "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_console1984_sensitive_accesses_on_session_id"
  end

  create_table "console1984_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "reason"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_console1984_sessions_on_created_at"
    t.index ["user_id", "created_at"], name: "index_console1984_sessions_on_user_id_and_created_at"
  end

  create_table "console1984_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["username"], name: "index_console1984_users_on_username"
  end

  create_table "elo_matches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "loser_project_id", null: false
    t.float "loser_rating_after", null: false
    t.float "loser_rating_before", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "winner_project_id", null: false
    t.float "winner_rating_after", null: false
    t.float "winner_rating_before", null: false
    t.index ["loser_project_id"], name: "index_elo_matches_on_loser_project_id"
    t.index ["user_id", "winner_project_id", "loser_project_id"], name: "index_elo_matches_on_user_and_ordered_pair", unique: true
    t.index ["user_id"], name: "index_elo_matches_on_user_id"
    t.index ["winner_project_id"], name: "index_elo_matches_on_winner_project_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "project_ratings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "originality", default: 3, null: false
    t.bigint "project_id", null: false
    t.integer "technical", default: 3, null: false
    t.datetime "updated_at", null: false
    t.integer "usability", default: 3, null: false
    t.bigint "user_id", null: false
    t.index ["project_id"], name: "index_project_ratings_on_project_id"
    t.index ["user_id", "project_id"], name: "index_project_ratings_on_user_id_and_project_id", unique: true
    t.index ["user_id"], name: "index_project_ratings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "access_token_ciphertext"
    t.text "address"
    t.boolean "admin"
    t.string "api_key"
    t.datetime "created_at", null: false
    t.string "display_name_from_slack"
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "name"
    t.string "provider"
    t.string "slack_id"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.string "verification_status"
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
  end

  create_table "webhook_subscriptions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.boolean "slack_dm", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.bigint "user_id", null: false
    t.index ["user_id", "event_type"], name: "index_webhook_subscriptions_on_user_id_and_event_type"
    t.index ["user_id"], name: "index_webhook_subscriptions_on_user_id"
  end

  create_table "ysws_project_entries", force: :cascade do |t|
    t.string "airtable_id"
    t.datetime "approved_at"
    t.string "archived_demo"
    t.string "archived_repo"
    t.string "code_url"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "demo_url"
    t.text "description"
    t.integer "elo_matches_count", default: 0, null: false
    t.float "elo_rating", default: 1500.0, null: false
    t.string "email"
    t.integer "github_stars"
    t.string "github_username"
    t.string "heard_through"
    t.decimal "hours_spent"
    t.decimal "hours_spent_actual"
    t.text "map_lat_ciphertext"
    t.text "map_long_ciphertext"
    t.string "playable_url"
    t.integer "ratings_count", default: 0, null: false
    t.decimal "ratings_median", precision: 3, scale: 2
    t.string "screenshot_url"
    t.datetime "updated_at", null: false
    t.boolean "viral_notified", default: false, null: false
    t.string "ysws"
    t.index ["airtable_id"], name: "index_ysws_project_entries_on_airtable_id", unique: true
    t.index ["approved_at"], name: "index_ysws_project_entries_on_approved_at"
    t.index ["country"], name: "index_ysws_project_entries_on_country"
    t.index ["elo_rating"], name: "index_ysws_project_entries_on_elo_rating"
    t.index ["email"], name: "index_ysws_project_entries_on_email"
    t.index ["github_stars"], name: "index_ysws_project_entries_on_github_stars"
    t.index ["ratings_median", "ratings_count"], name: "index_ysws_project_entries_on_ratings_median_and_ratings_count"
    t.index ["ysws"], name: "index_ysws_project_entries_on_ysws"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "elo_matches", "users"
  add_foreign_key "elo_matches", "ysws_project_entries", column: "loser_project_id"
  add_foreign_key "elo_matches", "ysws_project_entries", column: "winner_project_id"
  add_foreign_key "project_ratings", "users"
  add_foreign_key "project_ratings", "ysws_project_entries", column: "project_id"
  add_foreign_key "webhook_subscriptions", "users"
end
