# frozen_string_literal: true

module BrandColorPalette
  # Complete color palette
  Palette = Struct.new(
    :scheme,
    :base_hue,
    :colors,
    :metadata,
    :score,
    :accessibility,
    :variants,
    keyword_init: true
  ) do
    def self.from_hash(hash)
      new(
        scheme: hash[:scheme],
        base_hue: hash[:base_hue],
        colors: (hash[:colors] || []).map { |c| c.is_a?(PaletteColor) ? c : PaletteColor.from_hash(c) },
        metadata: hash[:metadata].is_a?(Hash) ? PaletteMetadata.from_hash(hash[:metadata]) : hash[:metadata],
        score: hash[:score],
        accessibility: hash[:accessibility].is_a?(Hash) ? AccessibilityReport.from_hash(hash[:accessibility]) : hash[:accessibility],
        variants: hash[:variants]
      )
    end

    def to_h
      {
        scheme: scheme,
        base_hue: base_hue,
        colors: colors.map(&:to_h),
        metadata: metadata.to_h,
        score: score,
        accessibility: accessibility&.to_h,
        variants: variants
      }
    end

    # Convenience methods
    def primary_color
      colors.find { |c| c.role == "primary" }
    end

    def background_color
      colors.find { |c| c.role == "background" }
    end

    def text_color
      colors.find { |c| c.role == "text" }
    end

    def accessible?
      accessibility&.valid == true
    end
  end
end
