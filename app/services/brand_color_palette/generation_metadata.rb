# frozen_string_literal: true

module BrandColorPalette
  # Generation metadata
  GenerationMetadata = Struct.new(
    :input,
    :design_vector,
    :descriptors,
    :primary_traits,
    :color_hints,
    :mapped_traits,
    :generated_at,
    keyword_init: true
  ) do
    def self.from_hash(hash)
      new(
        input: hash[:input].is_a?(Hash) ? BrandInput.from_hash(hash[:input]) : hash[:input],
        design_vector: hash[:design_vector].is_a?(Hash) ? DesignVector.from_hash(hash[:design_vector]) : hash[:design_vector],
        descriptors: hash[:descriptors] || [],
        primary_traits: hash[:primary_traits] || [],
        color_hints: hash[:color_hints] || [],
        mapped_traits: (hash[:mapped_traits] || []).map { |m| m.is_a?(TraitMapping) ? m : TraitMapping.new(**m) },
        generated_at: hash[:generated_at]
      )
    end

    def to_h
      {
        input: input.to_h,
        design_vector: design_vector.to_h,
        descriptors: descriptors,
        primary_traits: primary_traits,
        color_hints: color_hints,
        mapped_traits: mapped_traits.map(&:to_h),
        generated_at: generated_at
      }
    end
  end
end
