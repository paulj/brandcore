class CreatePaletteColours < ActiveRecord::Migration[8.1]
  def change
    create_table :palette_colours do |t|
      t.references :brand_colour_scheme, null: false, foreign_key: true
      t.string :colour_identifier, null: false
      t.string :name, null: false
      t.string :base_hex, null: false
      t.string :base_rgb
      t.string :base_hsl
      t.string :base_cmyk
      t.string :category, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :palette_colours, [ :brand_colour_scheme_id, :colour_identifier ], unique: true, name: "index_palette_colours_on_brand_and_identifier"
    add_index :palette_colours, :category
  end
end
