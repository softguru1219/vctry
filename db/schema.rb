# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_10_07_201231) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "ckeditor_assets", force: :cascade do |t|
    t.string "data_file_name", null: false
    t.string "data_content_type"
    t.integer "data_file_size"
    t.string "type", limit: 30
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type"], name: "index_ckeditor_assets_on_type"
  end

  create_table "content_creators", force: :cascade do |t|
    t.string "name"
    t.string "subtitle"
    t.string "description"
    t.string "code"
    t.string "logo"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "german_description"
    t.string "german_subtitle"
  end

  create_table "coupons", force: :cascade do |t|
    t.string "coupon_code"
    t.boolean "one_use", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "creator_id"
    t.integer "interval"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "friends", force: :cascade do |t|
    t.integer "user_a_id"
    t.integer "user_b_id"
    t.boolean "confirmed", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "groups", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "tournament_id"
    t.string "toornament_group_id"
    t.string "toornament_stage_id"
    t.integer "number"
    t.string "name"
    t.boolean "stage", default: false
    t.json "settings"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["tournament_id"], name: "index_groups_on_tournament_id"
    t.index ["user_id"], name: "index_groups_on_user_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "tournament_id"
    t.datetime "scheduled_datetime"
    t.string "public_note"
    t.string "private_note"
    t.string "toornament_match_id"
    t.string "status"
    t.string "group_id"
    t.string "stage_id"
    t.string "round_id"
    t.integer "number"
    t.string "match_type"
    t.json "settings"
    t.datetime "played_at"
    t.boolean "report_closed", default: false
    t.json "opponents"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "checked_in"
    t.json "scores"
    t.integer "submitter_id"
    t.integer "confirmer_id"
    t.integer "host_id"
    t.boolean "found_match", default: false
    t.index ["tournament_id"], name: "index_matches_on_tournament_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id"
    t.string "icon"
    t.string "url"
    t.string "message"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "requested_user"
    t.integer "tournament_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "participants", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "tournament_id"
    t.string "name"
    t.string "email"
    t.string "custom_user_identifier"
    t.boolean "checked_in", default: false
    t.json "custom_fields"
    t.string "partic_id"
    t.string "toornament_user_id"
    t.datetime "checked_in_at"
    t.json "lineup"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "match_id"
    t.boolean "had_game", default: false
    t.boolean "checked_game", default: false
    t.boolean "check_next_game", default: false
    t.index ["match_id"], name: "index_participants_on_match_id"
    t.index ["tournament_id"], name: "index_participants_on_tournament_id"
    t.index ["user_id"], name: "index_participants_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "payment_gateway_plan_identifier"
    t.string "name"
    t.string "price_currency", default: "USD", null: false
    t.integer "interval"
    t.integer "interval_count"
    t.string "status"
    t.boolean "until_sold"
    t.integer "plan_type", default: 0
    t.boolean "auto_renew", default: false
    t.text "description", default: ""
    t.integer "ordering", default: 0
    t.string "sb_plan_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "price_cents"
  end

  create_table "raffle_winners", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "raffle_id"
    t.integer "position"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "prize_name"
    t.string "prize_brand"
    t.integer "chances"
    t.index ["raffle_id"], name: "index_raffle_winners_on_raffle_id"
    t.index ["user_id"], name: "index_raffle_winners_on_user_id"
  end

  create_table "raffles", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "youtube"
    t.string "raffle_url"
    t.integer "cost", default: 1
    t.datetime "raffle_start_date"
    t.datetime "raffle_end_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "sponsor_banner"
    t.string "banner"
    t.string "twitter"
    t.string "facebook"
    t.string "reddit"
    t.string "google"
    t.string "vk"
    t.string "twitch"
    t.string "sponsor_name"
    t.string "prizes"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.integer "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id"
  end

  create_table "rounds", force: :cascade do |t|
    t.bigint "tournament_id"
    t.integer "number"
    t.string "name"
    t.boolean "closed"
    t.json "settings"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "toornament_round_id"
    t.string "round_group_id"
    t.string "round_stage_id"
    t.index ["tournament_id"], name: "index_rounds_on_tournament_id"
  end

  create_table "stages", force: :cascade do |t|
    t.bigint "tournament_id"
    t.string "toornament_stage_id"
    t.integer "number"
    t.string "name"
    t.string "stage_type"
    t.boolean "closed"
    t.json "settings"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["tournament_id"], name: "index_stages_on_tournament_id"
  end

  create_table "standings", force: :cascade do |t|
    t.bigint "tournament_id"
    t.integer "rank"
    t.integer "position"
    t.integer "ptc_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "toornament_standing_id"
    t.index ["tournament_id"], name: "index_standings_on_tournament_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "plan_id"
    t.string "subscription_type"
    t.date "start_date"
    t.date "expires_on"
    t.string "paypal_subscription_id"
    t.integer "status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "price_cents", default: 0
    t.string "price_currency", default: "USD"
    t.string "period", default: "Month"
    t.string "description"
    t.integer "frequency"
    t.boolean "auto_bill_outstanding", default: true
    t.integer "tournament_id"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["tournament_id"], name: "index_subscriptions_on_tournament_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "name"
    t.string "full_name"
    t.string "timezone"
    t.boolean "public", default: false
    t.integer "size"
    t.boolean "online", default: false
    t.string "location"
    t.string "country"
    t.boolean "registration_enabled", default: false
    t.datetime "registration_opening_datetime"
    t.datetime "registration_closing_datetime"
    t.string "toornament_id"
    t.string "discipline"
    t.string "status"
    t.string "contact"
    t.string "discord"
    t.string "website"
    t.string "description"
    t.string "rules"
    t.boolean "match_report_enabled", default: false
    t.string "registration_request_message"
    t.boolean "check_in_enabled", default: false
    t.boolean "check_in_participant_enabled", default: false
    t.datetime "check_in_participant_start_datetime"
    t.datetime "check_in_participant_end_datetime"
    t.boolean "archived", default: false
    t.string "registration_acceptance_message"
    t.string "registration_refusal_message"
    t.boolean "registration_terms_enabled", default: false
    t.string "registration_terms_url"
    t.string "participant_type"
    t.integer "team_min_size"
    t.integer "team_max_size"
    t.string "organization"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "featured", default: false
    t.boolean "registration_notification_enabled", default: false
    t.integer "cost"
    t.datetime "scheduled_date_start"
    t.datetime "scheduled_date_end"
    t.float "price", default: 0.0
    t.string "logo"
    t.json "platforms"
    t.boolean "premium", default: true
    t.string "tournament_cover"
    t.string "youtube"
    t.string "twitter"
    t.string "facebook"
    t.string "reddit"
    t.string "google"
    t.string "vk"
    t.datetime "last_queried"
    t.string "banner"
    t.string "featured_image"
    t.boolean "single_play", default: true
    t.string "prize"
    t.boolean "visible", default: false
    t.string "instagram"
    t.boolean "protection", default: false
    t.string "protection_pwd"
    t.string "mobile_cover"
    t.string "mobile_logo"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "user_id"
    t.float "amount", default: 0.0
    t.string "paypal_id"
    t.integer "transaction_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "paypal_order_id"
    t.integer "transaction_source"
    t.integer "tournament_id"
    t.index ["tournament_id"], name: "index_transactions_on_tournament_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "role"
    t.string "username", null: false
    t.string "firstname"
    t.string "lastname"
    t.string "address"
    t.date "birthday"
    t.string "country"
    t.string "payment"
    t.string "fifa_id"
    t.string "heathstone_id"
    t.string "youtube"
    t.string "twitch_id"
    t.string "discord_id"
    t.string "battle_tag_id"
    t.string "psn_id"
    t.string "xbox_live_id"
    t.string "steam_id"
    t.string "full_name"
    t.integer "content_creator_id"
    t.string "avatar"
    t.string "cover"
    t.text "played_games", default: [], array: true
    t.text "user_message"
    t.boolean "had_game", default: false
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "confirmation_token"
    t.boolean "terms_and_conditions", default: false
    t.integer "tickets"
    t.datetime "last_ticket_claimed"
    t.string "epic_id"
    t.index ["content_creator_id"], name: "index_users_on_content_creator_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

end
