class CreateBrandNames < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_names do |t|
      t.references :brand, null: false, foreign_key: true
      t.string :name, null: false, index: { unique: true }
      t.string :domain_primary
      t.jsonb :domain_alternatives, default: []
      t.text :name_rationale
      t.jsonb :name_alternatives_considered, default: []
      t.boolean :completed, default: false, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
