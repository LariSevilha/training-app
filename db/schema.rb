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

ActiveRecord::Schema[7.2].define(version: 2025_03_15_021343) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "amount_meals", force: :cascade do |t|
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "comidas", force: :cascade do |t|
    t.string "name"
    t.integer "amount_meal_id"
    t.bigint "meal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["meal_id"], name: "index_comidas_on_meal_id"
  end

  create_table "exercises", force: :cascade do |t|
    t.string "name"
    t.string "video"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "meals", force: :cascade do |t|
    t.integer "meal_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "repeats", force: :cascade do |t|
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "series", force: :cascade do |t|
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trainings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "serie_id", null: false
    t.bigint "repeat_id", null: false
    t.bigint "exercise_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_trainings_on_exercise_id"
    t.index ["repeat_id"], name: "index_trainings_on_repeat_id"
    t.index ["serie_id"], name: "index_trainings_on_serie_id"
    t.index ["user_id"], name: "index_trainings_on_user_id"
  end

  create_table "user_types", force: :cascade do |t|
    t.string "permission"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.integer "permission_id"
    t.string "email"
    t.string "password"
    t.string "avatar"
    t.bigint "user_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_type_id"], name: "index_users_on_user_type_id"
  end

  add_foreign_key "comidas", "meals"
  add_foreign_key "trainings", "exercises"
  add_foreign_key "trainings", "repeats"
  add_foreign_key "trainings", "series"
  add_foreign_key "trainings", "users"
  add_foreign_key "users", "user_types"
end
