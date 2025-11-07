# frozen_string_literal: true

module BrandColorPalette
  # Normalizes and processes brand inputs, mapping to design axes
  class NlpNormalizer
    # Design axes that influence color selection
    DESIGN_AXES = {
      warmth: 0.0,      # -1 (cool) to +1 (warm)
      boldness: 0.0,    # -1 (subtle) to +1 (bold)
      playfulness: 0.0, # -1 (serious) to +1 (playful)
      modernity: 0.0,   # -1 (classic) to +1 (modern)
      contrast: 0.0,    # -1 (low) to +1 (high)
      saturation: 0.0   # -1 (muted) to +1 (vibrant)
    }.freeze

    # Keyword to axis mappings
    KEYWORD_AXES = {
      "speed" => { modernity: 0.3, boldness: 0.2 },
      "automation" => { modernity: 0.4, warmth: -0.2 },
      "reliability" => { warmth: -0.1, boldness: -0.1 },
      "innovation" => { modernity: 0.5, saturation: 0.3 },
      "simplicity" => { contrast: -0.2, saturation: -0.2 },
      "power" => { boldness: 0.5, contrast: 0.4 },
      "elegance" => { contrast: 0.2, saturation: -0.1 },
      "fun" => { playfulness: 0.6, saturation: 0.4 }
    }.freeze

    attr_reader :brand_input, :design_vector, :trait_mapper, :mapped_traits

    def initialize(brand_input, trait_mapper: nil)
      @brand_input = brand_input
      @design_vector = DESIGN_AXES.dup
      @trait_mapper = trait_mapper || TraitMapper.new
      @mapped_traits = []
    end

    # Process brand inputs and compute design vector
    def normalize
      process_traits
      process_tones
      process_audiences
      process_keywords
      apply_category_adjustments
      apply_market_adjustments

      clamp_design_vector!

      {
        design_vector: @design_vector,
        descriptors: extract_descriptors,
        primary_traits: extract_primary_traits,
        color_hints: extract_color_hints,
        mapped_traits: @mapped_traits
      }
    end

    private

    def process_traits
      return unless brand_input[:traits]

      brand_input[:traits].each do |trait|
        # Try direct lookup first
        color_data = EmotionColorMap.color_for_trait(trait)

        # If not found, try mapping via embeddings
        unless color_data
          mapped_trait = @trait_mapper.map_trait(trait)
          if mapped_trait
            color_data = EmotionColorMap.color_for_trait(mapped_trait)
            @mapped_traits << { original: trait, mapped: mapped_trait } if color_data
          end
        end

        next unless color_data

        @design_vector[:warmth] += color_data[:warmth] * 0.3
        @design_vector[:saturation] += color_data[:saturation] * 0.3
      end
    end

    def process_tones
      return unless brand_input[:tone]

      brand_input[:tone].each do |tone|
        modifier = EmotionColorMap.modifier_for_tone(tone)
        @design_vector[:contrast] += modifier[:contrast_boost] * 0.4

        # Tone influences playfulness and modernity
        case tone.downcase
        when "playful"
          @design_vector[:playfulness] += 0.5
        when "serious", "authoritative"
          @design_vector[:playfulness] -= 0.4
        when "friendly"
          @design_vector[:warmth] += 0.3
        when "confident"
          @design_vector[:boldness] += 0.3
        end
      end
    end

    def process_audiences
      return unless brand_input[:audiences]

      brand_input[:audiences].each do |audience|
        case audience.downcase
        when "prosumer", "consumer"
          @design_vector[:playfulness] += 0.2
          @design_vector[:warmth] += 0.2
        when "enterprise", "b2b"
          @design_vector[:playfulness] -= 0.3
          @design_vector[:modernity] += 0.1
        when "smb"
          @design_vector[:warmth] += 0.1
        when "developer", "technical"
          @design_vector[:modernity] += 0.4
          @design_vector[:contrast] += 0.2
        end
      end
    end

    def process_keywords
      return unless brand_input[:keywords]

      brand_input[:keywords].each do |keyword|
        keyword_lower = keyword.to_s.downcase
        KEYWORD_AXES.each do |key, axes_adjustments|
          next unless keyword_lower.include?(key)

          axes_adjustments.each do |axis, value|
            @design_vector[axis] += value * 0.25
          end
        end
      end
    end

    def apply_category_adjustments
      return unless brand_input[:category]

      priors = EmotionColorMap.priors_for_category(brand_input[:category])
      @design_vector[:warmth] += priors[:warmth_bias] * 0.4
    end

    def apply_market_adjustments
      return unless brand_input[:markets]

      # Average market preferences if multiple markets
      total_sat = 0.0
      total_bright = 0.0
      count = 0

      brand_input[:markets].each do |market|
        adj = EmotionColorMap.adjustments_for_market(market)
        total_sat += adj[:saturation_preference]
        total_bright += adj[:brightness_preference]
        count += 1
      end

      return if count.zero?

      avg_sat = total_sat / count
      avg_bright = total_bright / count

      # Normalize saturation preference to -1 to 1 range (0.5 is neutral)
      @design_vector[:saturation] += (avg_sat - 0.7) * 0.5
    end

    def clamp_design_vector!
      @design_vector.transform_values! { |v| [ [ v, -1.0 ].max, 1.0 ].min }
    end

    def extract_descriptors
      descriptors = []
      descriptors << "warm" if @design_vector[:warmth] > 0.3
      descriptors << "cool" if @design_vector[:warmth] < -0.3
      descriptors << "bold" if @design_vector[:boldness] > 0.3
      descriptors << "subtle" if @design_vector[:boldness] < -0.3
      descriptors << "playful" if @design_vector[:playfulness] > 0.3
      descriptors << "serious" if @design_vector[:playfulness] < -0.3
      descriptors << "modern" if @design_vector[:modernity] > 0.3
      descriptors << "vibrant" if @design_vector[:saturation] > 0.3
      descriptors << "muted" if @design_vector[:saturation] < -0.3
      descriptors
    end

    def extract_primary_traits
      (brand_input[:traits] || []).first(3)
    end

    def extract_color_hints
      hints = []

      # Get hints from original traits
      (brand_input[:traits] || []).each do |trait|
        color_data = EmotionColorMap.color_for_trait(trait)
        hints.concat(color_data[:families]) if color_data
      end

      # Also get hints from mapped traits
      @mapped_traits.each do |mapping|
        color_data = EmotionColorMap.color_for_trait(mapping[:mapped])
        hints.concat(color_data[:families]) if color_data
      end

      hints.uniq
    end
  end
end
