class CreateBrandTypographies < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_typographies do |t|
      t.references :brand, null: false, foreign_key: true, index: { unique: true }
      t.string :scheme, null: false, default: "primary_secondary"
      t.text :usage_guidelines
      t.boolean :completed, default: false, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
