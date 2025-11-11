class PaletteShade < ApplicationRecord
  has_paper_trail

  belongs_to :palette_colour

  validates :stop, presence: true, numericality: { only_integer: true }, uniqueness: { scope: :palette_colour_id }
  validates :hex, presence: true, format: { with: /\A#[0-9A-F]{6}\z/i }
  validates :name, presence: true
end
