class CreateBrandUis < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_uis do |t|
      t.references :brand, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :button_styles, default: {}
      t.jsonb :form_elements, default: {}
      t.jsonb :iconography, default: {}
      t.jsonb :spacing_system, default: {}
      t.jsonb :grid_system, default: {}
      t.jsonb :component_patterns, default: {}
      t.boolean :completed, default: false, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
