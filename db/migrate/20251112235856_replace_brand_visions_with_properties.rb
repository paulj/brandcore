# frozen_string_literal: true

# Replace the brand_visions table with a flexible brand_properties table.
# This allows for dynamic property management with status tracking and AI suggestions.
class ReplaceBrandVisionsWithProperties < ActiveRecord::Migration[8.1]
  def change
    # Create the brand_properties table
    create_table :brand_properties do |t|
      t.references :brand, null: false, foreign_key: true, index: true
      t.string :property_name, null: false
      t.jsonb :value, null: false, default: {}
      t.string :status, null: false, default: "current"
      t.datetime :generated_at
      t.datetime :accepted_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    # Add composite indexes for common queries
    add_index :brand_properties, [ :brand_id, :property_name, :status ], name: "index_brand_properties_on_brand_name_status"
    add_index :brand_properties, [ :property_name, :status ], name: "index_brand_properties_on_name_status"
    add_index :brand_properties, :status

    # Drop the old brand_visions table
    drop_table :brand_visions, if_exists: true
  end
end
