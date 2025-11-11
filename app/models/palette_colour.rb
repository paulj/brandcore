class PaletteColour < ApplicationRecord
  has_paper_trail

  belongs_to :brand_colour_scheme
  has_many :palette_shades, -> { order(:stop) }, dependent: :destroy
  has_many :token_assignments, dependent: :restrict_with_error

  validates :colour_identifier, presence: true, uniqueness: { scope: :brand_colour_scheme_id }
  validates :name, presence: true
  validates :base_hex, presence: true, format: { with: /\A#[0-9A-F]{6}\z/i }
  validates :category, presence: true, inclusion: { in: %w[primary secondary accent neutral semantic] }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def shade_at(stop)
    palette_shades.find_by(stop: stop)
  end
end
