class BrandLanguage < ApplicationRecord
  has_paper_trail

  belongs_to :brand

  validates :brand_id, uniqueness: true
end
