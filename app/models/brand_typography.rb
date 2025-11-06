class BrandTypography < ApplicationRecord
  has_paper_trail

  belongs_to :brand

  has_many_attached :font_files

  validates :brand_id, uniqueness: true
end
