class BrandColourScheme < ApplicationRecord
  has_paper_trail

  belongs_to :brand
  has_many :palette_colours, dependent: :destroy
  has_many :palette_shades, through: :palette_colours
  has_many :token_assignments, dependent: :destroy

  validates :brand_id, uniqueness: true
end
