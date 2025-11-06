class CreatePaletteShades < ActiveRecord::Migration[8.1]
  def change
    create_table :palette_shades do |t|
      t.references :brand_colour_scheme, null: false, foreign_key: true
      t.integer :stop, null: false
      t.string :hex, null: false
      t.string :rgb
      t.string :hsl
      t.string :name, null: false

      t.timestamps
    end

    add_index :palette_shades, [ :brand_colour_scheme_id, :stop ], unique: true
  end
end
