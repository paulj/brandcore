class CreatePaletteShades < ActiveRecord::Migration[8.1]
  def change
    create_table :palette_shades do |t|
      t.references :palette_colour, null: false, foreign_key: true
      t.integer :stop, null: false
      t.string :hex, null: false
      t.string :rgb
      t.string :hsl
      t.string :name, null: false

      t.timestamps
    end

    add_index :palette_shades, [ :palette_colour_id, :stop ], unique: true
  end
end
