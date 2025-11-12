# frozen_string_literal: true

module BrandColorPalette
  # Individual color in a palette
  PaletteColor = Struct.new(
    :role,
    :oklch,
    :rgb,
    :hex,
    :cmyk,
    keyword_init: true
  ) do
    def self.from_hash(hash)
      new(
        role: hash[:role],
        oklch: hash[:oklch].is_a?(Hash) ? OklchColor.new(**hash[:oklch]) : hash[:oklch],
        rgb: hash[:rgb].is_a?(Hash) ? RgbColor.new(**hash[:rgb]) : hash[:rgb],
        hex: hash[:hex],
        cmyk: hash[:cmyk].is_a?(Hash) ? CmykColor.new(**hash[:cmyk]) : hash[:cmyk]
      )
    end

    def to_h
      {
        role: role,
        oklch: oklch.to_h,
        rgb: rgb.to_h,
        hex: hex,
        cmyk: cmyk.to_h
      }
    end
  end
end
