# frozen_string_literal: true

module BrandColorPalette
  # Struct definitions for brand color palette generation
  # These provide type-safe, self-documenting data structures

  # Brand input structure
  BrandInput = Struct.new(
    :brand_id,
    :traits,
    :tone,
    :audiences,
    :category,
    :markets,
    :keywords,
    keyword_init: true
  ) do
    # Create from hash with defaults
    def self.from_hash(hash)
      new(
        brand_id: hash[:brand_id] || hash["brand_id"],
        traits: hash[:traits] || hash["traits"] || [],
        tone: hash[:tone] || hash["tone"] || [],
        audiences: hash[:audiences] || hash["audiences"] || [],
        category: hash[:category] || hash["category"],
        markets: hash[:markets] || hash["markets"] || [],
        keywords: hash[:keywords] || hash["keywords"] || []
      )
    end

    # Convert to hash (for backward compatibility)
    def to_h
      {
        brand_id: brand_id,
        traits: traits,
        tone: tone,
        audiences: audiences,
        category: category,
        markets: markets,
        keywords: keywords
      }
    end
  end

  # Design vector structure
  DesignVector = Struct.new(
    :warmth,
    :boldness,
    :playfulness,
    :modernity,
    :contrast,
    :saturation,
    keyword_init: true
  ) do
    def self.from_hash(hash)
      new(
        warmth: hash[:warmth] || 0.0,
        boldness: hash[:boldness] || 0.0,
        playfulness: hash[:playfulness] || 0.0,
        modernity: hash[:modernity] || 0.0,
        contrast: hash[:contrast] || 0.0,
        saturation: hash[:saturation] || 0.0
      )
    end

    def to_h
      {
        warmth: warmth,
        boldness: boldness,
        playfulness: playfulness,
        modernity: modernity,
        contrast: contrast,
        saturation: saturation
      }
    end
  end

  # OKLCH color representation
  OklchColor = Struct.new(:l, :c, :h, keyword_init: true) do
    def to_h
      { l: l, c: c, h: h }
    end
  end

  # RGB color representation
  RgbColor = Struct.new(:r, :g, :b, keyword_init: true) do
    def to_h
      { r: r, g: g, b: b }
    end
  end

  # CMYK color representation
  CmykColor = Struct.new(:c, :m, :y, :k, keyword_init: true) do
    def to_h
      { c: c, m: m, y: y, k: k }
    end
  end

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

  # Accessibility evaluation results
  AccessibilityReport = Struct.new(
    :valid,
    :contrast_ratio,
    :wcag_aa_normal,
    :wcag_aa_large,
    :wcag_aaa_normal,
    :recommendations,
    keyword_init: true
  ) do
    def self.from_hash(hash)
      new(
        valid: hash[:valid],
        contrast_ratio: hash[:contrast_ratio],
        wcag_aa_normal: hash[:wcag_aa_normal],
        wcag_aa_large: hash[:wcag_aa_large],
        wcag_aaa_normal: hash[:wcag_aaa_normal],
        recommendations: hash[:recommendations] || []
      )
    end

    def to_h
      {
        valid: valid,
        contrast_ratio: contrast_ratio,
        wcag_aa_normal: wcag_aa_normal,
        wcag_aa_large: wcag_aa_large,
        wcag_aaa_normal: wcag_aaa_normal,
        recommendations: recommendations
      }
    end
  end

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

  # Trait mapping information
  TraitMapping = Struct.new(:original, :mapped, keyword_init: true) do
    def to_h
      { original: original, mapped: mapped }
    end
  end

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
