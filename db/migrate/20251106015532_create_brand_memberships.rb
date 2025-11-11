class CreateBrandMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_memberships do |t|
      t.references :brand, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "editor"
      t.references :invited_by_user, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :brand_memberships, [ :brand_id, :user_id ], unique: true
  end
end
