# frozen_string_literal: true

module BrandColorPalette
  # Generates color palettes using OKLCH and various harmony schemes
  class PaletteGenerator
    # Color harmony schemes
    HARMONY_SCHEMES = {
      analogous: ->(h) { [ h, (h + 30) % 360, (h - 30) % 360 ] },
      complementary: ->(h) { [ h, (h + 180) % 360 ] },
      triadic: ->(h) { [ h, (h + 120) % 360, (h + 240) % 360 ] },
      split_complementary: ->(h) { [ h, (h + 150) % 360, (h + 210) % 360 ] },
      tetradic: ->(h) { [ h, (h + 90) % 360, (h + 180) % 360, (h + 270) % 360 ] },
      monochromatic: ->(h) { [ h ] }
    }.freeze

    attr_reader :normalized_data, :design_vector

    def initialize(normalized_data)
      @normalized_data = normalized_data
      @design_vector = normalized_data[:design_vector]
    end

    # Generate multiple palette candidates
    # @param count [Integer] Number of palettes to generate
    # @return [Array<Hash>] Array of palette hashes
    def generate(count: 10)
      palettes = []

      # Determine dominant hues from traits
      dominant_hues = extract_dominant_hues

      # Generate palettes with different harmony schemes
      HARMONY_SCHEMES.each do |scheme_name, scheme_func|
        dominant_hues.first(3).each do |base_hue|
          palette = generate_palette_with_scheme(base_hue, scheme_name, scheme_func)
          palettes << palette if palette
        end
      end

      # Take top N palettes
      palettes.first(count)
    end

    private

    def extract_dominant_hues
      hues = []

      # Get hues from primary traits
      @normalized_data[:primary_traits].each do |trait|
        color_data = EmotionColorMap.color_for_trait(trait)
        hues.concat(color_data[:hues]) if color_data
      end

      # If no hues from traits, use default based on design vector
      if hues.empty?
        hues = if @design_vector[:warmth] > 0.3
                 [ 30, 15, 45 ] # Warm colors
        elsif @design_vector[:warmth] < -0.3
                 [ 210, 200, 220 ] # Cool colors
        else
                 [ 180, 200, 280 ] # Neutral/tech colors
        end
      end

      hues.uniq
    end

    def generate_palette_with_scheme(base_hue, scheme_name, scheme_func)
      # Generate harmony hues
      harmony_hues = scheme_func.call(base_hue)

      # Determine lightness and chroma based on design vector
      base_lightness = calculate_base_lightness
      base_chroma = calculate_base_chroma

      # Build color roles
      colors = []

      # Primary color (main brand color)
      primary = create_color(
        harmony_hues[0],
        base_lightness,
        base_chroma,
        role: "primary"
      )
      colors << primary

      # Secondary color
      if harmony_hues[1]
        secondary = create_color(
          harmony_hues[1],
          base_lightness + 0.05,
          base_chroma * 0.8,
          role: "secondary"
        )
        colors << secondary
      end

      # Accent color
      accent_hue = harmony_hues[2] || (harmony_hues[0] + 180) % 360
      accent = create_color(
        accent_hue,
        base_lightness - 0.05,
        base_chroma * 1.1,
        role: "accent"
      )
      colors << accent

      # Neutrals (grays)
      colors << create_color(harmony_hues[0], 0.95, 0.02, role: "background")
      colors << create_color(harmony_hues[0], 0.20, 0.01, role: "text")
      colors << create_color(harmony_hues[0], 0.85, 0.03, role: "neutral-light")
      colors << create_color(harmony_hues[0], 0.50, 0.02, role: "neutral-mid")
      colors << create_color(harmony_hues[0], 0.30, 0.02, role: "neutral-dark")

      {
        scheme: scheme_name,
        base_hue: base_hue,
        colors: colors,
        metadata: {
          descriptors: @normalized_data[:descriptors],
          harmony_scheme: scheme_name,
          design_vector: @design_vector
        }
      }
    end

    def create_color(hue, lightness, chroma, role:)
      # Clamp values
      l = [ [ lightness, 0.0 ].max, 1.0 ].min
      c = [ [ chroma, 0.0 ].max, 0.4 ].min
      h = hue % 360

      # Convert to RGB
      rgb = ColorSpace.oklch_to_srgb(l, c, h)
      hex = ColorSpace.rgb_to_hex(rgb[:r], rgb[:g], rgb[:b])
      cmyk = ColorSpace.rgb_to_cmyk(rgb[:r], rgb[:g], rgb[:b])

      {
        role: role,
        oklch: { l: l.round(3), c: c.round(3), h: h.round(1) },
        rgb: rgb,
        hex: hex,
        cmyk: cmyk
      }
    end

    def calculate_base_lightness
      # Base lightness around 0.5-0.6 for primary colors
      lightness = 0.55

      # Adjust based on design vector
      lightness += @design_vector[:contrast] * 0.1
      lightness -= @design_vector[:boldness] * 0.05

      [ [ lightness, 0.3 ].max, 0.7 ].min
    end

    def calculate_base_chroma
      # Base chroma (saturation in OKLCH)
      chroma = 0.15

      # Adjust based on design vector
      chroma += @design_vector[:saturation] * 0.08
      chroma += @design_vector[:boldness] * 0.05
      chroma -= @design_vector[:playfulness] * -0.03

      [ [ chroma, 0.05 ].max, 0.3 ].min
    end
  end
end
