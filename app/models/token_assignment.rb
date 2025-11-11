class TokenAssignment < ApplicationRecord
  has_paper_trail

  belongs_to :brand_colour_scheme
  belongs_to :palette_colour, optional: true

  validates :token_role, presence: true, uniqueness: { scope: :brand_colour_scheme_id }
  validate :has_colour_source

  private

  def has_colour_source
    if palette_colour.nil? && override_hex.blank?
      errors.add(:base, "Must have either palette_colour or override_hex")
    end
  end
end
