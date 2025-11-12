class BrandVision < ApplicationRecord
  has_paper_trail

  belongs_to :brand
  has_many :suggestions, as: :suggestionable, dependent: :destroy

  # Structured JSONB attributes
  attribute :core_values, CoreValue.to_array_type
  attribute :traits, :string, array: true, default: []
  attribute :tone, :string, array: true, default: []
  attribute :markets, :string, array: true, default: []
  attribute :audiences, :string, array: true, default: []
  attribute :keywords, :string, array: true, default: []

  validates :brand_id, uniqueness: true

  # Convert to hash for palette generator compatibility
  def to_h
    {
      brand_id: brand_id,
      traits: traits || [],
      tone: tone || [],
      audiences: audiences || [],
      category: category,
      markets: markets || [],
      keywords: keywords || []
    }
  end
end
