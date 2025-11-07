# frozen_string_literal: true

module BrandColorPalette
  # Maps brand traits, tones, and categories to color families and hues
  class EmotionColorMap
    # Trait to color family mapping
    # Each trait maps to color hues (in OKLCH hue degrees 0-360) and metadata
    TRAIT_COLOR_MAP = {
      # Trust & Reliability
      "trustworthy" => { hues: [ 210, 220, 230 ], families: [ "blue" ], warmth: -0.2, saturation: 0.6 },
      "reliable" => { hues: [ 210, 220 ], families: [ "blue", "slate" ], warmth: -0.1, saturation: 0.5 },
      "professional" => { hues: [ 210, 225, 240 ], families: [ "blue", "navy" ], warmth: -0.2, saturation: 0.5 },

      # Innovation & Technology
      "innovative" => { hues: [ 190, 200, 280 ], families: [ "cyan", "blue", "purple" ], warmth: 0.0, saturation: 0.7 },
      "modern" => { hues: [ 180, 190, 270 ], families: [ "cyan", "purple" ], warmth: 0.1, saturation: 0.7 },
      "tech" => { hues: [ 195, 205, 215 ], families: [ "blue", "cyan" ], warmth: -0.1, saturation: 0.8 },

      # Energy & Power
      "energetic" => { hues: [ 0, 15, 30 ], families: [ "red", "orange" ], warmth: 0.8, saturation: 0.9 },
      "powerful" => { hues: [ 355, 5, 15 ], families: [ "red" ], warmth: 0.6, saturation: 0.8 },
      "bold" => { hues: [ 350, 0, 20 ], families: [ "red", "orange" ], warmth: 0.7, saturation: 0.9 },

      # Growth & Nature
      "growth" => { hues: [ 120, 140, 160 ], families: [ "green", "teal" ], warmth: 0.2, saturation: 0.6 },
      "sustainable" => { hues: [ 110, 130, 150 ], families: [ "green" ], warmth: 0.3, saturation: 0.6 },
      "natural" => { hues: [ 100, 120, 140 ], families: [ "green", "earth" ], warmth: 0.4, saturation: 0.5 },

      # Creativity & Optimism
      "creative" => { hues: [ 50, 280, 300 ], families: [ "yellow", "purple", "magenta" ], warmth: 0.5, saturation: 0.8 },
      "optimistic" => { hues: [ 45, 55, 65 ], families: [ "yellow", "orange" ], warmth: 0.7, saturation: 0.8 },
      "cheerful" => { hues: [ 40, 50, 60 ], families: [ "yellow" ], warmth: 0.8, saturation: 0.9 },

      # Luxury & Premium
      "premium" => { hues: [ 270, 280, 0 ], families: [ "purple", "black", "gold" ], warmth: 0.1, saturation: 0.6 },
      "luxury" => { hues: [ 275, 285, 295 ], families: [ "purple", "violet" ], warmth: 0.0, saturation: 0.7 },
      "sophisticated" => { hues: [ 260, 270, 280 ], families: [ "purple", "navy" ], warmth: -0.1, saturation: 0.5 },

      # Approachable & Friendly
      "approachable" => { hues: [ 35, 160, 190 ], families: [ "orange", "teal", "cyan" ], warmth: 0.4, saturation: 0.6 },
      "friendly" => { hues: [ 30, 150, 180 ], families: [ "orange", "teal" ], warmth: 0.5, saturation: 0.7 },
      "warm" => { hues: [ 20, 30, 40 ], families: [ "orange", "coral" ], warmth: 0.9, saturation: 0.7 },

      # Calm & Balance
      "calm" => { hues: [ 180, 200, 220 ], families: [ "blue", "teal" ], warmth: -0.2, saturation: 0.4 },
      "balanced" => { hues: [ 140, 160, 180 ], families: [ "teal", "green" ], warmth: 0.0, saturation: 0.5 },
      "peaceful" => { hues: [ 170, 190, 210 ], families: [ "blue", "cyan" ], warmth: -0.1, saturation: 0.4 }
    }.freeze

    # Tone modifiers that adjust lightness and contrast
    TONE_MODIFIERS = {
      "confident" => { lightness_shift: -0.05, contrast_boost: 0.15 },
      "gentle" => { lightness_shift: 0.10, contrast_boost: -0.10 },
      "playful" => { lightness_shift: 0.05, contrast_boost: 0.10 },
      "serious" => { lightness_shift: -0.10, contrast_boost: -0.05 },
      "friendly" => { lightness_shift: 0.08, contrast_boost: 0.05 },
      "authoritative" => { lightness_shift: -0.12, contrast_boost: 0.20 }
    }.freeze

    # Category color priors (common industry color associations)
    CATEGORY_PRIORS = {
      "SaaS" => { preferred_hues: [ 200, 210, 220 ], avoid_hues: [], warmth_bias: -0.2 },
      "fintech" => { preferred_hues: [ 210, 120 ], avoid_hues: [ 0 ], warmth_bias: -0.3 },
      "healthcare" => { preferred_hues: [ 200, 160 ], avoid_hues: [ 120 ], warmth_bias: 0.0 },
      "ecommerce" => { preferred_hues: [ 0, 30, 200 ], avoid_hues: [], warmth_bias: 0.2 },
      "education" => { preferred_hues: [ 210, 120, 50 ], avoid_hues: [], warmth_bias: 0.1 },
      "food" => { preferred_hues: [ 0, 30, 120 ], avoid_hues: [ 210 ], warmth_bias: 0.5 },
      "entertainment" => { preferred_hues: [ 280, 0, 50 ], avoid_hues: [], warmth_bias: 0.3 }
    }.freeze

    # Market/regional color preferences
    MARKET_ADJUSTMENTS = {
      "US" => { saturation_preference: 0.7, brightness_preference: 0.0 },
      "EU" => { saturation_preference: 0.6, brightness_preference: -0.05 },
      "AU" => { saturation_preference: 0.75, brightness_preference: 0.05 },
      "JP" => { saturation_preference: 0.5, brightness_preference: 0.10 },
      "CN" => { saturation_preference: 0.8, brightness_preference: 0.0 }
    }.freeze

    class << self
      # Get color data for a trait
      def color_for_trait(trait)
        TRAIT_COLOR_MAP[trait.to_s.downcase]
      end

      # Get all traits matching a color family
      def traits_for_family(family)
        TRAIT_COLOR_MAP.select { |_trait, data| data[:families].include?(family) }.keys
      end

      # Get tone modifier data
      def modifier_for_tone(tone)
        TONE_MODIFIERS[tone.to_s.downcase] || { lightness_shift: 0.0, contrast_boost: 0.0 }
      end

      # Get category color priors
      def priors_for_category(category)
        CATEGORY_PRIORS[category.to_s] || { preferred_hues: [], avoid_hues: [], warmth_bias: 0.0 }
      end

      # Get market adjustments
      def adjustments_for_market(market)
        MARKET_ADJUSTMENTS[market.to_s] || { saturation_preference: 0.7, brightness_preference: 0.0 }
      end
    end
  end
end
