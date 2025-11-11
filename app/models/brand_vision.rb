class BrandVision < ApplicationRecord
  has_paper_trail

  belongs_to :brand

  # Structured JSONB attributes
  attribute :core_values, CoreValue.to_array_type
  attribute :traits, :string, array: true, default: []
  attribute :tone, :string, array: true, default: []
  attribute :markets, :string, array: true, default: []

  validates :brand_id, uniqueness: true
end
