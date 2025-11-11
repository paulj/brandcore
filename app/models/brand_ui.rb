class BrandUi < ApplicationRecord
  has_paper_trail

  belongs_to :brand

  has_many_attached :component_examples

  validates :brand_id, uniqueness: true
end
