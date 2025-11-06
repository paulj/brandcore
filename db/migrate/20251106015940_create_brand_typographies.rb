class CreateBrandTypographies < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_typographies do |t|
      t.references :brand, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :primary_typeface, default: {}
      t.jsonb :secondary_typeface, default: {}
      t.jsonb :type_scale, default: {}
      t.jsonb :line_heights, default: {}
      t.text :usage_guidelines
      t.jsonb :web_font_urls, default: []
      t.boolean :completed, default: false, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
