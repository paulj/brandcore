class CreateBrandColourSchemes < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_colour_schemes do |t|
      t.references :brand, null: false, foreign_key: true, index: { unique: true }
      t.string :palette_generation_method
      t.text :usage_guidelines
      t.jsonb :accessibility_analysis
      t.jsonb :aesthetic_analysis
      t.datetime :accessibility_last_analyzed_at
      t.boolean :completed, default: false, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
