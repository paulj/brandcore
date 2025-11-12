class CreateSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :suggestions do |t|
      t.references :suggestionable, polymorphic: true, null: false
      t.string :field_name, null: false
      t.jsonb :content, null: false, default: {}
      t.integer :status, null: false, default: 0
      t.datetime :chosen_at
      t.datetime :archived_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :suggestions, [ :suggestionable_type, :suggestionable_id, :field_name, :status ],
              name: "index_suggestions_on_suggestionable_and_field_and_status"
    add_index :suggestions, :status
  end
end
