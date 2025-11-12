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

ActiveRecord::Schema[8.1].define(version: 2025_11_12_023125) do
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

  create_table "brand_concepts", force: :cascade do |t|
    t.bigint "brand_id", null: false
    t.boolean "completed", default: false, null: false
    t.datetime "completed_at"
    t.text "concept"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_brand_concepts_on_brand_id", unique: true
  end

  create_table "brand_languages", force: :cascade do |t|
    t.bigint "brand_id", null: false
    t.boolean "completed", default: false, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "example_copy"
    t.jsonb "messaging_pillars", default: []
    t.string "tagline"
    t.jsonb "tone_of_voice", default: {}
    t.datetime "updated_at", null: false
    t.jsonb "vocabulary_guidelines", default: {}
    t.text "writing_style_notes"
    t.index ["brand_id"], name: "index_brand_languages_on_brand_id", unique: true
  end

  create_table "brand_logos", force: :cascade do |t|
    t.bigint "brand_id", null: false
    t.boolean "completed", default: false, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "logo_philosophy"
    t.datetime "updated_at", null: false
    t.jsonb "usage_guidelines", default: {}
    t.index ["brand_id"], name: "index_brand_logos_on_brand_id", unique: true
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

  create_table "brand_names", force: :cascade do |t|
    t.bigint "brand_id", null: false
    t.boolean "completed", default: false, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.jsonb "domain_alternatives", default: []
    t.string "domain_primary"
    t.string "name", null: false
    t.jsonb "name_alternatives_considered", default: []
    t.text "name_rationale"
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_brand_names_on_brand_id"
    t.index ["name"], name: "index_brand_names_on_name", unique: true
  end

  create_table "brand_typographies", force: :cascade do |t|
    t.bigint "brand_id", null: false
    t.boolean "completed", default: false, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "scheme", default: "primary_secondary", null: false
    t.datetime "updated_at", null: false
    t.text "usage_guidelines"
    t.index ["brand_id"], name: "index_brand_typographies_on_brand_id", unique: true
  end

  create_table "brand_uis", force: :cascade do |t|
    t.bigint "brand_id", null: false
    t.jsonb "button_styles", default: {}
    t.boolean "completed", default: false, null: false
    t.datetime "completed_at"
    t.jsonb "component_patterns", default: {}
    t.datetime "created_at", null: false
    t.jsonb "form_elements", default: {}
    t.jsonb "grid_system", default: {}
    t.jsonb "iconography", default: {}
    t.jsonb "spacing_system", default: {}
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_brand_uis_on_brand_id", unique: true
  end

  create_table "brand_visions", force: :cascade do |t|
    t.string "audiences", default: [], array: true
    t.bigint "brand_id", null: false
    t.jsonb "brand_personality", default: {}
    t.text "brand_positioning"
    t.string "category"
    t.boolean "completed", default: false, null: false
    t.datetime "completed_at"
    t.jsonb "core_values", default: []
    t.datetime "created_at", null: false
    t.string "keywords", default: [], array: true
    t.string "markets", default: [], array: true
    t.text "mission_statement"
    t.text "target_audience"
    t.string "tone", default: [], array: true
    t.string "traits", default: [], array: true
    t.datetime "updated_at", null: false
    t.text "vision_statement"
    t.index ["brand_id"], name: "index_brand_visions_on_brand_id", unique: true
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
    t.datetime "created_at", null: false
    t.string "hex", null: false
    t.string "hsl"
    t.string "name", null: false
    t.bigint "palette_colour_id", null: false
    t.string "rgb"
    t.integer "stop", null: false
    t.datetime "updated_at", null: false
    t.index ["palette_colour_id", "stop"], name: "index_palette_shades_on_palette_colour_id_and_stop", unique: true
    t.index ["palette_colour_id"], name: "index_palette_shades_on_palette_colour_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
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

  create_table "typefaces", force: :cascade do |t|
    t.bigint "brand_typography_id", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "family", null: false
    t.string "google_fonts_url"
    t.jsonb "line_heights", default: {}
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "role", null: false
    t.text "subsets", default: [], array: true
    t.jsonb "type_scale", default: {}
    t.datetime "updated_at", null: false
    t.text "variants", default: [], array: true
    t.index ["brand_typography_id", "role"], name: "index_typefaces_on_brand_typography_and_role", unique: true
    t.index ["brand_typography_id"], name: "index_typefaces_on_brand_typography_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "brand_colour_schemes", "brands"
  add_foreign_key "brand_concepts", "brands"
  add_foreign_key "brand_languages", "brands"
  add_foreign_key "brand_logos", "brands"
  add_foreign_key "brand_memberships", "brands"
  add_foreign_key "brand_memberships", "users"
  add_foreign_key "brand_memberships", "users", column: "invited_by_user_id"
  add_foreign_key "brand_names", "brands"
  add_foreign_key "brand_typographies", "brands"
  add_foreign_key "brand_uis", "brands"
  add_foreign_key "brand_visions", "brands"
  add_foreign_key "palette_colours", "brand_colour_schemes"
  add_foreign_key "palette_shades", "palette_colours"
  add_foreign_key "sessions", "users"
  add_foreign_key "token_assignments", "brand_colour_schemes"
  add_foreign_key "token_assignments", "palette_colours"
  add_foreign_key "typefaces", "brand_typographies"
end
