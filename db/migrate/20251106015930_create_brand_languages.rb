class CreateBrandLanguages < ActiveRecord::Migration[8.1]
  def change
    create_table :brand_languages do |t|
      t.references :brand, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :tone_of_voice, default: {}
      t.jsonb :messaging_pillars, default: []
      t.string :tagline
      t.jsonb :vocabulary_guidelines, default: {}
      t.text :writing_style_notes
      t.text :example_copy
      t.boolean :completed, default: false, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
