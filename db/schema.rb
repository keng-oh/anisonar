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

ActiveRecord::Schema[8.1].define(version: 2026_05_24_022159) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "anime_series", force: :cascade do |t|
    t.string "annict_series_id"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "name_en"
    t.datetime "updated_at", null: false
    t.index ["annict_series_id"], name: "index_anime_series_on_annict_series_id", unique: true
  end

  create_table "anime_songs", force: :cascade do |t|
    t.bigint "anime_id", null: false
    t.datetime "created_at", null: false
    t.string "episode_range"
    t.bigint "song_id", null: false
    t.integer "song_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["anime_id", "song_id"], name: "index_anime_songs_on_anime_id_and_song_id", unique: true
    t.index ["anime_id"], name: "index_anime_songs_on_anime_id"
    t.index ["song_id"], name: "index_anime_songs_on_song_id"
  end

  create_table "animes", force: :cascade do |t|
    t.bigint "anime_series_id"
    t.string "annict_id"
    t.string "cover_image_url"
    t.datetime "created_at", null: false
    t.integer "media_type", default: 0, null: false
    t.string "season"
    t.integer "series_order"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.string "title_en"
    t.datetime "updated_at", null: false
    t.index ["anime_series_id"], name: "index_animes_on_anime_series_id"
    t.index ["annict_id"], name: "index_animes_on_annict_id", unique: true
  end

  create_table "artist_relations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "from_artist_id", null: false
    t.integer "relation_type", null: false
    t.bigint "to_artist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["from_artist_id", "to_artist_id", "relation_type"], name: "index_artist_relations_unique", unique: true
    t.index ["from_artist_id"], name: "index_artist_relations_on_from_artist_id"
    t.index ["to_artist_id"], name: "index_artist_relations_on_to_artist_id"
  end

  create_table "artists", force: :cascade do |t|
    t.bigint "anime_id"
    t.integer "approve_count", default: 0, null: false
    t.integer "artist_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_user_id"
    t.string "image_url"
    t.datetime "last_reviewed_at"
    t.string "name", null: false
    t.string "name_kana"
    t.integer "reject_count", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_user_id"
    t.index ["anime_id"], name: "index_artists_on_anime_id"
    t.index ["created_by_user_id"], name: "index_artists_on_created_by_user_id"
    t.index ["updated_by_user_id"], name: "index_artists_on_updated_by_user_id"
  end

  create_table "platform_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "platform", null: false
    t.string "platform_track_id", null: false
    t.bigint "song_id", null: false
    t.datetime "updated_at", null: false
    t.index ["song_id", "platform"], name: "index_platform_links_on_song_id_and_platform", unique: true
    t.index ["song_id"], name: "index_platform_links_on_song_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "action", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.bigint "reviewable_id", null: false
    t.string "reviewable_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "weight", default: 1, null: false
    t.index ["reviewable_type", "reviewable_id", "user_id"], name: "index_reviews_on_reviewable_and_user", unique: true
    t.index ["reviewable_type", "reviewable_id"], name: "index_reviews_on_reviewable"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "series_songs", force: :cascade do |t|
    t.bigint "anime_series_id", null: false
    t.datetime "created_at", null: false
    t.bigint "song_id", null: false
    t.integer "song_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["anime_series_id", "song_id"], name: "index_series_songs_on_anime_series_id_and_song_id", unique: true
    t.index ["anime_series_id"], name: "index_series_songs_on_anime_series_id"
    t.index ["song_id"], name: "index_series_songs_on_song_id"
  end

  create_table "songs", force: :cascade do |t|
    t.integer "approve_count", default: 0, null: false
    t.bigint "artist_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_user_id"
    t.datetime "last_reviewed_at"
    t.text "notes"
    t.integer "reject_count", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_user_id"
    t.index ["artist_id"], name: "index_songs_on_artist_id"
    t.index ["created_by_user_id"], name: "index_songs_on_created_by_user_id"
    t.index ["updated_by_user_id"], name: "index_songs_on_updated_by_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "trusted_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "anime_songs", "animes"
  add_foreign_key "anime_songs", "songs"
  add_foreign_key "animes", "anime_series"
  add_foreign_key "artist_relations", "artists", column: "from_artist_id"
  add_foreign_key "artist_relations", "artists", column: "to_artist_id"
  add_foreign_key "artists", "animes"
  add_foreign_key "artists", "users", column: "created_by_user_id"
  add_foreign_key "artists", "users", column: "updated_by_user_id"
  add_foreign_key "platform_links", "songs"
  add_foreign_key "reviews", "users"
  add_foreign_key "series_songs", "anime_series"
  add_foreign_key "series_songs", "songs"
  add_foreign_key "songs", "artists"
  add_foreign_key "songs", "users", column: "created_by_user_id"
  add_foreign_key "songs", "users", column: "updated_by_user_id"
end
