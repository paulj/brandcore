class CreateBrandVisions < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_visions do |t|
      t.references :brand, null: false, foreign_key: true, index: { unique: true }
      t.text :mission_statement
      t.text :vision_statement
      t.jsonb :core_values, default: []
      t.text :brand_positioning
      t.text :target_audience
      t.jsonb :brand_personality, default: {}
      t.boolean :completed, default: false, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
