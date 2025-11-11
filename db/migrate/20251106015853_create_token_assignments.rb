class CreateTokenAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :token_assignments do |t|
      t.references :brand_colour_scheme, null: false, foreign_key: true
      t.references :palette_colour, null: true, foreign_key: true
      t.string :token_role, null: false
      t.integer :shade_stop
      t.string :override_hex

      t.timestamps
    end

    add_index :token_assignments, [ :brand_colour_scheme_id, :token_role ], unique: true, name: "index_token_assignments_on_brand_and_role"
    add_index :token_assignments, :token_role
  end
end
