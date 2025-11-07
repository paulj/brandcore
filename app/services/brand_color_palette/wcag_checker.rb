# frozen_string_literal: true

module BrandColorPalette
  # WCAG accessibility checker for color contrast compliance
  class WcagChecker
    # WCAG 2.1 contrast ratio requirements
    WCAG_AA_NORMAL = 4.5
    WCAG_AA_LARGE = 3.0
    WCAG_AAA_NORMAL = 7.0
    WCAG_AAA_LARGE = 4.5

    class << self
      # Calculate relative luminance for sRGB color
      # @param r [Integer] Red (0-255)
      # @param g [Integer] Green (0-255)
      # @param b [Integer] Blue (0-255)
      # @return [Float] Relative luminance
      def relative_luminance(r, g, b)
        r_norm = linearize_rgb_component(r / 255.0)
        g_norm = linearize_rgb_component(g / 255.0)
        b_norm = linearize_rgb_component(b / 255.0)

        0.2126 * r_norm + 0.7152 * g_norm + 0.0722 * b_norm
      end

      # Calculate contrast ratio between two colors
      # @param color1 [Hash] RGB hash {r:, g:, b:}
      # @param color2 [Hash] RGB hash {r:, g:, b:}
      # @return [Float] Contrast ratio
      def contrast_ratio(color1, color2)
        l1 = relative_luminance(color1[:r], color1[:g], color1[:b])
        l2 = relative_luminance(color2[:r], color2[:g], color2[:b])

        lighter = [ l1, l2 ].max
        darker = [ l1, l2 ].min

        (lighter + 0.05) / (darker + 0.05)
      end

      # Check if contrast meets WCAG AA for normal text
      # @param color1 [Hash] RGB hash
      # @param color2 [Hash] RGB hash
      # @return [Boolean]
      def meets_aa_normal?(color1, color2)
        contrast_ratio(color1, color2) >= WCAG_AA_NORMAL
      end

      # Check if contrast meets WCAG AA for large text
      # @param color1 [Hash] RGB hash
      # @param color2 [Hash] RGB hash
      # @return [Boolean]
      def meets_aa_large?(color1, color2)
        contrast_ratio(color1, color2) >= WCAG_AA_LARGE
      end

      # Check if contrast meets WCAG AAA for normal text
      # @param color1 [Hash] RGB hash
      # @param color2 [Hash] RGB hash
      # @return [Boolean]
      def meets_aaa_normal?(color1, color2)
        contrast_ratio(color1, color2) >= WCAG_AAA_NORMAL
      end

      # Evaluate palette accessibility
      # @param palette [Hash] Palette with :colors array
      # @return [Hash] Accessibility report
      def evaluate_palette(palette)
        colors = palette[:colors]
        background = colors.find { |c| c[:role] == "background" }
        text = colors.find { |c| c[:role] == "text" }

        return { valid: false, reason: "Missing background or text colors" } unless background && text

        bg_rgb = background[:rgb]
        text_rgb = text[:rgb]
        ratio = contrast_ratio(bg_rgb, text_rgb)

        {
          valid: meets_aa_normal?(bg_rgb, text_rgb),
          contrast_ratio: ratio.round(2),
          wcag_aa_normal: meets_aa_normal?(bg_rgb, text_rgb),
          wcag_aa_large: meets_aa_large?(bg_rgb, text_rgb),
          wcag_aaa_normal: meets_aaa_normal?(bg_rgb, text_rgb),
          recommendations: generate_recommendations(ratio)
        }
      end

      # Adjust lightness to meet contrast requirements
      # @param color_oklch [Hash] OKLCH color {l:, c:, h:}
      # @param target_rgb [Hash] Target background RGB
      # @param min_ratio [Float] Minimum contrast ratio
      # @return [Hash] Adjusted OKLCH color
      def adjust_for_contrast(color_oklch, target_rgb, min_ratio: WCAG_AA_NORMAL)
        original = color_oklch.dup
        adjusted = original.dup

        # Try adjusting lightness
        50.times do |i|
          rgb = ColorSpace.oklch_to_srgb(adjusted[:l], adjusted[:c], adjusted[:h])
          ratio = contrast_ratio(rgb, target_rgb)

          return adjusted if ratio >= min_ratio

          # Determine direction: make lighter or darker
          target_lum = relative_luminance(target_rgb[:r], target_rgb[:g], target_rgb[:b])
          current_lum = relative_luminance(rgb[:r], rgb[:g], rgb[:b])

          if current_lum > target_lum
            # Make lighter
            adjusted[:l] = [ adjusted[:l] + 0.02, 1.0 ].min
          else
            # Make darker
            adjusted[:l] = [ adjusted[:l] - 0.02, 0.0 ].max
          end

          # Prevent infinite loop at extremes
          break if adjusted[:l] >= 0.99 || adjusted[:l] <= 0.01
        end

        adjusted
      end

      private

      def linearize_rgb_component(component)
        if component <= 0.03928
          component / 12.92
        else
          ((component + 0.055) / 1.055)**2.4
        end
      end

      def generate_recommendations(ratio)
        return [] if ratio >= WCAG_AAA_NORMAL

        recs = []
        recs << "Consider increasing contrast for better readability" if ratio < WCAG_AA_NORMAL
        recs << "Meets AA but not AAA - consider adjusting for enhanced accessibility" if ratio >= WCAG_AA_NORMAL && ratio < WCAG_AAA_NORMAL
        recs
      end
    end
  end
end
