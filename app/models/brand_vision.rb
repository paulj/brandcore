class BrandVision < ApplicationRecord
  has_paper_trail

  belongs_to :brand

  # Structured JSONB attributes
  attribute :core_values, CoreValue.to_array_type

  validates :brand_id, uniqueness: true
end
