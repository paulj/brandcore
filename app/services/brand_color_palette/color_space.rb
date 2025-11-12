# frozen_string_literal: true

module BrandColorPalette
  # Handles color space conversions, particularly OKLCH ↔ sRGB
  # OKLCH provides perceptual uniformity for color generation
  class ColorSpace
    class << self
      # Convert OKLCH to sRGB
      # @param l [Float] Lightness (0-1)
      # @param c [Float] Chroma (0-0.4 typically)
      # @param h [Float] Hue angle (0-360)
      # @return [Hash] RGB values {r:, g:, b:} in 0-255 range
      def oklch_to_srgb(l, c, h)
        # Convert OKLCH to OKLab
        h_rad = h * Math::PI / 180.0
        a = c * Math.cos(h_rad)
        b = c * Math.sin(h_rad)

        # Convert OKLab to linear RGB
        l_ = l + 0.3963377774 * a + 0.2158037573 * b
        m_ = l - 0.1055613458 * a - 0.0638541728 * b
        s_ = l - 0.0894841775 * a - 1.2914855480 * b

        l_linear = l_**3
        m_linear = m_**3
        s_linear = s_**3

        # Convert linear RGB to sRGB
        r_linear = 4.0767416621 * l_linear - 3.3077115913 * m_linear + 0.2309699292 * s_linear
        g_linear = -1.2684380046 * l_linear + 2.6097574011 * m_linear - 0.3413193965 * s_linear
        b_linear = -0.0041960863 * l_linear - 0.7034186147 * m_linear + 1.7076147010 * s_linear

        # Apply gamma correction
        r = gamma_correct(r_linear)
        g = gamma_correct(g_linear)
        b = gamma_correct(b_linear)

        # Clamp and convert to 0-255 range
        {
          r: clamp((r * 255).round, 0, 255),
          g: clamp((g * 255).round, 0, 255),
          b: clamp((b * 255).round, 0, 255)
        }
      end

      # Convert sRGB to OKLCH
      # @param r [Integer] Red (0-255)
      # @param g [Integer] Green (0-255)
      # @param b [Integer] Blue (0-255)
      # @return [Hash] OKLCH values {l:, c:, h:}
      def srgb_to_oklch(r, g, b)
        # Normalize to 0-1 and apply inverse gamma
        r_linear = inverse_gamma(r / 255.0)
        g_linear = inverse_gamma(g / 255.0)
        b_linear = inverse_gamma(b / 255.0)

        # Convert sRGB to linear LMS
        l = 0.4122214708 * r_linear + 0.5363325363 * g_linear + 0.0514459929 * b_linear
        m = 0.2119034982 * r_linear + 0.6806995451 * g_linear + 0.1073969566 * b_linear
        s = 0.0883024619 * r_linear + 0.2817188376 * g_linear + 0.6299787005 * b_linear

        # Convert to OKLab
        l_ = Math.cbrt(l)
        m_ = Math.cbrt(m)
        s_ = Math.cbrt(s)

        lab_l = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
        lab_a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
        lab_b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

        # Convert OKLab to OKLCH
        c = Math.sqrt(lab_a**2 + lab_b**2)
        h = (Math.atan2(lab_b, lab_a) * 180.0 / Math::PI) % 360

        { l: lab_l, c: c, h: h }
      end

      # Convert RGB to HEX
      # @param r [Integer] Red (0-255)
      # @param g [Integer] Green (0-255)
      # @param b [Integer] Blue (0-255)
      # @return [String] Hex color code
      def rgb_to_hex(r, g, b)
        "#%02x%02x%02x" % [ r, g, b ]
      end

      # Convert HEX to RGB
      # @param hex [String] Hex color code
      # @return [Hash] RGB values {r:, g:, b:}
      def hex_to_rgb(hex)
        hex = hex.delete("#")
        {
          r: hex[0..1].to_i(16),
          g: hex[2..3].to_i(16),
          b: hex[4..5].to_i(16)
        }
      end

      # Convert RGB to CMYK (for print)
      # @param r [Integer] Red (0-255)
      # @param g [Integer] Green (0-255)
      # @param b [Integer] Blue (0-255)
      # @return [Hash] CMYK values {c:, m:, y:, k:} in 0-100 range
      def rgb_to_cmyk(r, g, b)
        r_prime = r / 255.0
        g_prime = g / 255.0
        b_prime = b / 255.0

        k = 1 - [ r_prime, g_prime, b_prime ].max

        return { c: 0, m: 0, y: 0, k: 100 } if k == 1

        c = ((1 - r_prime - k) / (1 - k) * 100).round
        m = ((1 - g_prime - k) / (1 - k) * 100).round
        y = ((1 - b_prime - k) / (1 - k) * 100).round
        k = (k * 100).round

        { c: c, m: m, y: y, k: k }
      end

      private

      def gamma_correct(linear)
        if linear <= 0.0031308
          12.92 * linear
        else
          1.055 * (linear**(1.0 / 2.4)) - 0.055
        end
      end

      def inverse_gamma(srgb)
        if srgb <= 0.04045
          srgb / 12.92
        else
          ((srgb + 0.055) / 1.055)**2.4
        end
      end

      def clamp(value, min, max)
        [ [ value, min ].max, max ].min
      end
    end
  end
end
