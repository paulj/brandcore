class CreateBrands < ActiveRecord::Migration[8.1]
  def change
    create_table :brands do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.boolean :is_working_name, default: true, null: false
      t.string :status, default: "draft", null: false

      t.timestamps
    end
    add_index :brands, :slug, unique: true
  end
end
