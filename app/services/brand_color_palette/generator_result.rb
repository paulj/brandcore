# frozen_string_literal: true

module BrandColorPalette
  # Complete generation result
  GeneratorResult = Struct.new(
    :brand_id,
    :palettes,
    :metadata,
    keyword_init: true
  ) do
    def self.from_hash(hash)
      new(
        brand_id: hash[:brand_id],
        palettes: (hash[:palettes] || []).map { |p| p.is_a?(Palette) ? p : Palette.from_hash(p) },
        metadata: hash[:metadata].is_a?(Hash) ? GenerationMetadata.from_hash(hash[:metadata]) : hash[:metadata]
      )
    end

    def to_h
      {
        brand_id: brand_id,
        palettes: palettes.map(&:to_h),
        metadata: metadata.to_h
      }
    end

    # Convenience method to get best palette
    def best_palette
      palettes.first
    end

    # Get palettes that meet accessibility standards
    def accessible_palettes
      palettes.select(&:accessible?)
    end
  end
end
