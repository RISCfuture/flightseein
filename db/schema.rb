# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2014_05_03_083406) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "aircraft", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ident", limit: 16, null: false
    t.boolean "has_image", default: false, null: false
    t.text "metadata"
    t.index ["user_id", "ident"], name: "aircraft_ident", unique: true
  end

  create_table "airports", id: :serial, force: :cascade do |t|
    t.string "site_number", limit: 11, null: false
    t.string "lid", limit: 4
    t.string "icao", limit: 4
    t.string "iata", limit: 4
    t.text "metadata"
    t.index ["iata"], name: "airports_iata"
    t.index ["icao"], name: "airports_icao"
    t.index ["lid", "icao", "iata"], name: "airports_ident", unique: true
    t.index ["lid"], name: "airports_lid"
    t.index ["site_number"], name: "airports_site_number_key", unique: true
  end

  create_table "destinations", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "airport_id", null: false
    t.boolean "has_photo", default: false, null: false
    t.integer "flights_count", default: 0, null: false
    t.text "metadata"
    t.index ["user_id", "airport_id"], name: "destinations_pkey", unique: true
    t.index ["user_id", "has_photo"], name: "dest_user_photo"
  end

  create_table "flights", id: :serial, force: :cascade do |t|
    t.string "logbook_id", limit: 60, null: false
    t.integer "user_id", null: false
    t.integer "origin_id", null: false
    t.integer "destination_id", null: false
    t.integer "aircraft_id", null: false
    t.float "duration", null: false
    t.date "date", null: false
    t.boolean "has_blog", default: false, null: false
    t.boolean "has_photos", default: false, null: false
    t.integer "sequence"
    t.text "metadata"
    t.index ["user_id", "destination_id", "sequence"], name: "flights_user_dest"
    t.index ["user_id", "has_blog", "sequence"], name: "flights_user_blog"
    t.index ["user_id", "logbook_id"], name: "flights_logbook_id", unique: true
    t.index ["user_id", "sequence"], name: "flights_user", unique: true
  end

# Could not dump table "imports" because of following StandardError
#   Unknown type 'state_type' for column 'state'

  create_table "occupants", id: :serial, force: :cascade do |t|
    t.integer "flight_id", null: false
    t.integer "person_id", null: false
    t.string "role", limit: 126
    t.index ["flight_id"], name: "occupants_flight"
    t.index ["person_id"], name: "occupants_person"
  end

  create_table "people", id: :serial, force: :cascade do |t|
    t.string "logbook_id", limit: 60, null: false
    t.integer "user_id", null: false
    t.float "hours", default: 0.0, null: false
    t.boolean "has_photo", default: false, null: false
    t.boolean "me", default: false, null: false
    t.text "metadata"
    t.index ["user_id", "has_photo", "me", "hours"], name: "people_user_photo_me_hours"
    t.index ["user_id", "logbook_id"], name: "people_logbook_id", unique: true
    t.index ["user_id", "me", "hours"], name: "people_user_me_hours"
  end

  create_table "photographs", id: :serial, force: :cascade do |t|
    t.integer "flight_id", null: false
    t.text "metadata"
    t.index ["flight_id"], name: "photographs_flight"
  end

# Could not dump table "slugs" because of following StandardError
#   Unknown type 'slugged_class' for column 'sluggable_type'

  create_table "stops", id: false, force: :cascade do |t|
    t.integer "destination_id", null: false
    t.integer "flight_id", null: false
    t.integer "sequence", null: false
    t.index ["destination_id", "flight_id"], name: "stops_pkey", unique: true
    t.index ["flight_id", "sequence"], name: "stops_in_sequence"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", limit: 255, null: false
    t.string "subdomain", limit: 32, null: false
    t.boolean "active", default: true, null: false
    t.boolean "has_avatar", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.text "metadata"
    t.index ["email"], name: "users_email_key", unique: true
    t.index ["subdomain"], name: "users_subdomain_key", unique: true
  end

  add_foreign_key "aircraft", "users", name: "aircraft_user_id_fkey", on_delete: :cascade
  add_foreign_key "destinations", "airports", name: "destinations_airport_id_fkey", on_delete: :restrict
  add_foreign_key "destinations", "users", name: "destinations_user_id_fkey", on_delete: :cascade
  add_foreign_key "flights", "aircraft", name: "flights_aircraft_id_fkey", on_delete: :restrict
  add_foreign_key "flights", "destinations", column: "user_id", primary_key: "user_id", name: "flights_user_id_fkey1", on_delete: :restrict
  add_foreign_key "flights", "destinations", column: "user_id", primary_key: "user_id", name: "flights_user_id_fkey2", on_delete: :restrict
  add_foreign_key "flights", "users", name: "flights_user_id_fkey", on_delete: :cascade
  add_foreign_key "imports", "users", name: "imports_user_id_fkey", on_delete: :cascade
  add_foreign_key "occupants", "flights", name: "occupants_flight_id_fkey", on_delete: :cascade
  add_foreign_key "occupants", "people", name: "occupants_person_id_fkey", on_delete: :restrict
  add_foreign_key "people", "users", name: "people_user_id_fkey", on_delete: :cascade
  add_foreign_key "photographs", "flights", name: "photographs_flight_id_fkey", on_delete: :cascade
  add_foreign_key "stops", "flights", name: "stops_flight_id_fkey", on_delete: :cascade
end
