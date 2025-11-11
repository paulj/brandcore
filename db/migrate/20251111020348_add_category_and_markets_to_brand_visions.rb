class AddCategoryAndMarketsToBrandVisions < ActiveRecord::Migration[8.1]
  def change
    add_column :brand_visions, :category, :string
    add_column :brand_visions, :markets, :string, default: [], array: true
  end
end
