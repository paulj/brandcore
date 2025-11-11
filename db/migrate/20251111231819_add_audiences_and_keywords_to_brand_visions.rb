class AddAudiencesAndKeywordsToBrandVisions < ActiveRecord::Migration[8.1]
  def change
    add_column :brand_visions, :audiences, :string, default: [], array: true
    add_column :brand_visions, :keywords, :string, default: [], array: true
  end
end
