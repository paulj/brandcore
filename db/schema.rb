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

ActiveRecord::Schema[8.1].define(version: 2025_11_06_015853) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "brand_colour_schemes", force: :cascade do |t|
    t.jsonb "accessibility_analysis"
    t.datetime "accessibility_last_analyzed_at"
    t.jsonb "aesthetic_analysis"
    t.bigint "brand_id", null: false
    t.boolean "completed", default: false, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "palette_generation_method"
    t.datetime "updated_at", null: false
    t.text "usage_guidelines"
    t.index ["brand_id"], name: "index_brand_colour_schemes_on_brand_id", unique: true
  end

  create_table "brand_memberships", force: :cascade do |t|
    t.bigint "brand_id", null: false
    t.datetime "created_at", null: false
    t.bigint "invited_by_user_id"
    t.string "role", default: "editor", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["brand_id", "user_id"], name: "index_brand_memberships_on_brand_id_and_user_id", unique: true
    t.index ["brand_id"], name: "index_brand_memberships_on_brand_id"
    t.index ["invited_by_user_id"], name: "index_brand_memberships_on_invited_by_user_id"
    t.index ["user_id"], name: "index_brand_memberships_on_user_id"
  end

  create_table "brands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_working_name", default: true, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_brands_on_slug", unique: true
  end

  create_table "palette_colours", force: :cascade do |t|
    t.string "base_cmyk"
    t.string "base_hex", null: false
    t.string "base_hsl"
    t.string "base_rgb"
    t.bigint "brand_colour_scheme_id", null: false
    t.string "category", null: false
    t.string "colour_identifier", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["brand_colour_scheme_id", "colour_identifier"], name: "index_palette_colours_on_brand_and_identifier", unique: true
    t.index ["brand_colour_scheme_id"], name: "index_palette_colours_on_brand_colour_scheme_id"
    t.index ["category"], name: "index_palette_colours_on_category"
  end

  create_table "palette_shades", force: :cascade do |t|
    t.bigint "brand_colour_scheme_id", null: false
    t.datetime "created_at", null: false
    t.string "hex", null: false
    t.string "hsl"
    t.string "name", null: false
    t.string "rgb"
    t.integer "stop", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_colour_scheme_id", "stop"], name: "index_palette_shades_on_brand_colour_scheme_id_and_stop", unique: true
    t.index ["brand_colour_scheme_id"], name: "index_palette_shades_on_brand_colour_scheme_id"
  end

  create_table "token_assignments", force: :cascade do |t|
    t.bigint "brand_colour_scheme_id", null: false
    t.datetime "created_at", null: false
    t.string "override_hex"
    t.bigint "palette_colour_id"
    t.integer "shade_stop"
    t.string "token_role", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_colour_scheme_id", "token_role"], name: "index_token_assignments_on_brand_and_role", unique: true
    t.index ["brand_colour_scheme_id"], name: "index_token_assignments_on_brand_colour_scheme_id"
    t.index ["palette_colour_id"], name: "index_token_assignments_on_palette_colour_id"
    t.index ["token_role"], name: "index_token_assignments_on_token_role"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "brand_colour_schemes", "brands"
  add_foreign_key "brand_memberships", "brands"
  add_foreign_key "brand_memberships", "users"
  add_foreign_key "brand_memberships", "users", column: "invited_by_user_id"
  add_foreign_key "palette_colours", "brand_colour_schemes"
  add_foreign_key "palette_shades", "brand_colour_schemes"
  add_foreign_key "token_assignments", "brand_colour_schemes"
  add_foreign_key "token_assignments", "palette_colours"
end
