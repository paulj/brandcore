class AddTraitsAndToneToBrandVisions < ActiveRecord::Migration[8.1]
  def change
    add_column :brand_visions, :traits, :jsonb, default: []
    add_column :brand_visions, :tone, :jsonb, default: []
  end
end
