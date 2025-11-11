class BrandLogo < ApplicationRecord
  has_paper_trail

  belongs_to :brand

  has_one_attached :primary_logo
  has_many_attached :logo_variations

  validates :brand_id, uniqueness: true
end
