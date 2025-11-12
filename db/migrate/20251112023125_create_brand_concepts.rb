class CreateBrandConcepts < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_concepts do |t|
      t.references :brand, null: false, foreign_key: true, index: { unique: true }
      t.text :concept
      t.boolean :completed, null: false, default: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
