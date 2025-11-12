# frozen_string_literal: true

module BrandColorPalette
  # Palette metadata
  PaletteMetadata = Struct.new(
    :descriptors,
    :harmony_scheme,
    :design_vector,
    keyword_init: true
  ) do
    def self.from_hash(hash)
      new(
        descriptors: hash[:descriptors] || [],
        harmony_scheme: hash[:harmony_scheme],
        design_vector: hash[:design_vector].is_a?(Hash) ? DesignVector.from_hash(hash[:design_vector]) : hash[:design_vector]
      )
    end

    def to_h
      {
        descriptors: descriptors,
        harmony_scheme: harmony_scheme,
        design_vector: design_vector.to_h
      }
    end
  end
end
