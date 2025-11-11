class CreateBrandLogos < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_logos do |t|
      t.references :brand, null: false, foreign_key: true, index: { unique: true }
      t.text :logo_philosophy
      t.jsonb :usage_guidelines, default: {}
      t.boolean :completed, default: false, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
