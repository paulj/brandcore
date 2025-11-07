class BrandTypography < ApplicationRecord
  # has_paper_trail

  belongs_to :brand

  # Structured JSONB attributes
  attribute :primary_typeface, Typeface.to_type
  attribute :secondary_typeface, Typeface.to_type

  validates :brand_id, uniqueness: true
end
