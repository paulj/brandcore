# frozen_string_literal: true

module BrandColorPalette
  # Applies constraints and filters to palettes for accessibility, cultural fit, and category appropriateness
  class ConstraintLayer
    attr_reader :brand_input, :palettes

    def initialize(brand_input, palettes)
      @brand_input = brand_input
      @palettes = palettes
    end

    # Apply all constraints and return filtered, scored palettes
    # @return [Array<Hash>] Filtered and scored palettes
    def apply
      scored_palettes = @palettes.map do |palette|
        score = calculate_palette_score(palette)
        accessibility = evaluate_accessibility(palette)

        # Apply accessibility fixes if needed
        if !accessibility[:valid]
          palette = adjust_palette_for_accessibility(palette)
          accessibility = evaluate_accessibility(palette)
        end

        palette.merge(
          score: score,
          accessibility: accessibility
        )
      end

      # Sort by score (highest first) and return
      scored_palettes.sort_by { |p| -p[:score] }
    end

    # Generate light and dark mode variations
    # @param palette [Hash] Base palette
    # @return [Hash] Palette with light and dark variants
    def generate_mode_variations(palette)
      light_mode = palette.dup
      dark_mode = generate_dark_mode(palette)

      {
        light: light_mode,
        dark: dark_mode
      }
    end

    private

    def calculate_palette_score(palette)
      score = 100.0

      # Category fit penalty
      score -= category_penalty(palette)

      # Cultural fit penalty
      score -= cultural_penalty(palette)

      # Design vector alignment
      score += design_alignment_bonus(palette)

      [ score, 0.0 ].max
    end

    def category_penalty(palette)
      return 0.0 unless @brand_input[:category]

      priors = EmotionColorMap.priors_for_category(@brand_input[:category])
      penalty = 0.0

      primary_color = palette[:colors].find { |c| c[:role] == "primary" }
      return penalty unless primary_color

      primary_hue = primary_color[:oklch][:h]

      # Check if hue is in avoid list
      priors[:avoid_hues].each do |avoid_hue|
        distance = hue_distance(primary_hue, avoid_hue)
        penalty += 15 if distance < 30 # Within 30 degrees
      end

      # Check if hue is in preferred list (bonus)
      preferred_match = priors[:preferred_hues].any? do |pref_hue|
        hue_distance(primary_hue, pref_hue) < 40
      end
      penalty -= 10 if preferred_match

      penalty
    end

    def cultural_penalty(palette)
      return 0.0 unless @brand_input[:markets]

      penalty = 0.0
      primary_color = palette[:colors].find { |c| c[:role] == "primary" }
      return penalty unless primary_color

      primary_hue = primary_color[:oklch][:h]

      # Market-specific cultural considerations
      @brand_input[:markets].each do |market|
        case market.to_s
        when "CN"
          # Red is auspicious in China
          penalty -= 5 if hue_distance(primary_hue, 0) < 30
        when "JP"
          # Prefer muted, subtle colors
          chroma = primary_color[:oklch][:c]
          penalty += 5 if chroma > 0.25
        end
      end

      penalty
    end

    def design_alignment_bonus(palette)
      # Reward palettes that align with design vector
      bonus = 0.0

      primary_color = palette[:colors].find { |c| c[:role] == "primary" }
      return bonus unless primary_color

      # Check saturation alignment
      chroma = primary_color[:oklch][:c]
      saturation_vector = @brand_input.dig(:design_vector, :saturation) || 0.0

      if saturation_vector > 0.3 && chroma > 0.2
        bonus += 5
      elsif saturation_vector < -0.3 && chroma < 0.15
        bonus += 5
      end

      # Check warmth alignment
      warmth_vector = @brand_input.dig(:design_vector, :warmth) || 0.0
      hue = primary_color[:oklch][:h]

      if warmth_vector > 0.3 && (hue < 60 || hue > 330)
        bonus += 5
      elsif warmth_vector < -0.3 && (hue > 150 && hue < 270)
        bonus += 5
      end

      bonus
    end

    def evaluate_accessibility(palette)
      WcagChecker.evaluate_palette(palette)
    end

    def adjust_palette_for_accessibility(palette)
      # Adjust text color to meet contrast requirements
      background = palette[:colors].find { |c| c[:role] == "background" }
      text = palette[:colors].find { |c| c[:role] == "text" }

      return palette unless background && text

      # Adjust text color lightness
      adjusted_oklch = WcagChecker.adjust_for_contrast(
        text[:oklch],
        background[:rgb],
        min_ratio: WcagChecker::WCAG_AA_NORMAL
      )

      # Update text color
      rgb = ColorSpace.oklch_to_srgb(adjusted_oklch[:l], adjusted_oklch[:c], adjusted_oklch[:h])
      hex = ColorSpace.rgb_to_hex(rgb[:r], rgb[:g], rgb[:b])
      cmyk = ColorSpace.rgb_to_cmyk(rgb[:r], rgb[:g], rgb[:b])

      text[:oklch] = adjusted_oklch
      text[:rgb] = rgb
      text[:hex] = hex
      text[:cmyk] = cmyk

      palette
    end

    def generate_dark_mode(light_palette)
      dark_palette = light_palette.dup
      dark_colors = light_palette[:colors].map do |color|
        dark_color = color.dup

        # Invert lightness for backgrounds and neutrals
        if [ "background", "neutral-light", "neutral-mid" ].include?(color[:role])
          inverted_l = 1.0 - color[:oklch][:l]
          dark_oklch = color[:oklch].merge(l: inverted_l)

          rgb = ColorSpace.oklch_to_srgb(dark_oklch[:l], dark_oklch[:c], dark_oklch[:h])
          hex = ColorSpace.rgb_to_hex(rgb[:r], rgb[:g], rgb[:b])
          cmyk = ColorSpace.rgb_to_cmyk(rgb[:r], rgb[:g], rgb[:b])

          dark_color[:oklch] = dark_oklch
          dark_color[:rgb] = rgb
          dark_color[:hex] = hex
          dark_color[:cmyk] = cmyk
        elsif color[:role] == "text"
          # Make text light
          light_oklch = color[:oklch].merge(l: 0.95)
          rgb = ColorSpace.oklch_to_srgb(light_oklch[:l], light_oklch[:c], light_oklch[:h])
          hex = ColorSpace.rgb_to_hex(rgb[:r], rgb[:g], rgb[:b])
          cmyk = ColorSpace.rgb_to_cmyk(rgb[:r], rgb[:g], rgb[:b])

          dark_color[:oklch] = light_oklch
          dark_color[:rgb] = rgb
          dark_color[:hex] = hex
          dark_color[:cmyk] = cmyk
        end

        dark_color
      end

      dark_palette[:colors] = dark_colors
      dark_palette
    end

    def hue_distance(h1, h2)
      # Calculate shortest distance between two hues on color wheel
      diff = (h1 - h2).abs
      [ diff, 360 - diff ].min
    end
  end
end
