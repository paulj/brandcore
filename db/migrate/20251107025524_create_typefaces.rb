class CreateTypefaces < ActiveRecord::Migration[8.1]
  def change
    create_table :typefaces do |t|
      t.references :brand_typography, null: false, foreign_key: true, index: true
      t.string :role, null: false # e.g., "primary", "secondary", "heading", "body"
      t.string :name, null: false
      t.string :family, null: false
      t.string :category, null: false
      t.text :variants, array: true, default: []
      t.text :subsets, array: true, default: []
      t.string :google_fonts_url
      t.jsonb :type_scale, default: {} # e.g., { h1: "48px", h2: "36px", body: "16px" }
      t.jsonb :line_heights, default: {} # e.g., { heading: 1.2, body: 1.5 }
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    # Ensure unique role per brand_typography
    add_index :typefaces, [ :brand_typography_id, :role ], unique: true, name: "index_typefaces_on_brand_typography_and_role"
  end
end
