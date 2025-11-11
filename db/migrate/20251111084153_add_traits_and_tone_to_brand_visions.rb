class AddTraitsAndToneToBrandVisions < ActiveRecord::Migration[8.1]
  def change
    add_column :brand_visions, :traits, :string, default: [], array: true
    add_column :brand_visions, :tone, :string, default: [], array: true
  end
end
