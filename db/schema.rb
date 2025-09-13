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

ActiveRecord::Schema[7.2].define(version: 2025_09_12_222027) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "amount_meals", force: :cascade do |t|
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "api_keys", force: :cascade do |t|
    t.bigint "user_id"
    t.string "device_id", null: false
    t.string "token", null: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "master_user_id"
    t.bigint "super_user_id"
    t.index ["master_user_id"], name: "index_api_keys_on_master_user_id"
    t.index ["super_user_id"], name: "index_api_keys_on_super_user_id"
    t.index ["token"], name: "index_api_keys_on_token", unique: true
    t.index ["user_id", "device_id"], name: "index_api_keys_on_user_id_and_device_id", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "comidas", force: :cascade do |t|
    t.string "name"
    t.string "amount"
    t.bigint "meal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["meal_id"], name: "index_comidas_on_meal_id"
  end

  create_table "dashboard_settings", force: :cascade do |t|
    t.string "primary_color", null: false
    t.string "secondary_color", null: false
    t.string "tertiary_color", null: false
    t.string "app_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "master_user_id"
    t.index ["master_user_id"], name: "index_dashboard_settings_on_master_user_id"
  end

  create_table "exercises", force: :cascade do |t|
    t.string "name"
    t.string "video"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "master_users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone_number", null: false
    t.string "password_digest", null: false
    t.string "cpf", null: false
    t.string "cref", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cpf"], name: "index_master_users_on_cpf", unique: true
    t.index ["email"], name: "index_master_users_on_email", unique: true
  end

  create_table "meals", force: :cascade do |t|
    t.string "meal_type"
    t.integer "weekday", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_meals_on_user_id"
  end

  create_table "super_users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_super_users_on_email", unique: true
  end

  create_table "training_exercise_sets", force: :cascade do |t|
    t.bigint "training_exercise_id", null: false
    t.integer "series_amount", null: false
    t.integer "repeats_amount", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["training_exercise_id"], name: "index_training_exercise_sets_on_training_exercise_id"
  end

  create_table "training_exercises", force: :cascade do |t|
    t.bigint "training_id", null: false
    t.bigint "exercise_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_training_exercises_on_exercise_id"
    t.index ["training_id"], name: "index_training_exercises_on_training_id"
  end

  create_table "training_photos", force: :cascade do |t|
    t.bigint "training_id", null: false
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["training_id"], name: "index_training_photos_on_training_id"
  end

  create_table "trainings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "weekday", default: 0, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_trainings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.integer "permission_id"
    t.string "avatar"
    t.string "device_token"
    t.string "phone_number", default: "", null: false
    t.string "plan_duration"
    t.string "plan_type"
    t.datetime "registration_date"
    t.datetime "expiration_date"
    t.bigint "master_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "api_key"
    t.string "active_device_id"
    t.string "password_digest"
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["master_user_id"], name: "index_users_on_master_user_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "weekly_pdfs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "weekday"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_weekly_pdfs_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_keys", "master_users"
  add_foreign_key "api_keys", "super_users"
  add_foreign_key "api_keys", "users"
  add_foreign_key "comidas", "meals"
  add_foreign_key "dashboard_settings", "master_users"
  add_foreign_key "meals", "users"
  add_foreign_key "training_exercise_sets", "training_exercises"
  add_foreign_key "training_exercises", "exercises"
  add_foreign_key "training_exercises", "trainings"
  add_foreign_key "training_photos", "trainings"
  add_foreign_key "trainings", "users"
  add_foreign_key "users", "master_users"
  add_foreign_key "weekly_pdfs", "users"
end
