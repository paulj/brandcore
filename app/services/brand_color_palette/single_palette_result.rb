# frozen_string_literal: true

module BrandColorPalette
  # Single palette result (for generate_best)
  SinglePaletteResult = Struct.new(
    :brand_id,
    :palette,
    :metadata,
    keyword_init: true
  ) do
    def self.from_hash(hash)
      new(
        brand_id: hash[:brand_id],
        palette: hash[:palette].is_a?(Palette) ? hash[:palette] : Palette.from_hash(hash[:palette]),
        metadata: hash[:metadata].is_a?(Hash) ? GenerationMetadata.from_hash(hash[:metadata]) : hash[:metadata]
      )
    end

    def to_h
      {
        brand_id: brand_id,
        palette: palette.to_h,
        metadata: metadata.to_h
      }
    end
  end
end
