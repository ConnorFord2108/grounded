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

ActiveRecord::Schema.define(version: 2022_06_01_123248) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "destinations", force: :cascade do |t|
    t.text "description"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "latitude"
    t.float "longitude"
  end

  create_table "recommendations", force: :cascade do |t|
    t.bigint "destination_id", null: false
    t.string "name"
    t.text "description"
    t.integer "num_reviews"
    t.float "rating"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "photo_url"
    t.index ["destination_id"], name: "index_recommendations_on_destination_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "comment"
    t.integer "rating"
    t.bigint "travel_plan_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["travel_plan_id"], name: "index_reviews_on_travel_plan_id"
  end

  create_table "travel_plans", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.text "comment"
    t.bigint "user_id", null: false
    t.bigint "destination_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["destination_id"], name: "index_travel_plans_on_destination_id"
    t.index ["user_id"], name: "index_travel_plans_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "first_name"
    t.string "last_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "recommendations", "destinations"
  add_foreign_key "reviews", "travel_plans"
  add_foreign_key "travel_plans", "destinations"
  add_foreign_key "travel_plans", "users"
end
