# frozen_string_literal: true

module BrandColorPalette
  # Main orchestrator for the brand color palette generation pipeline
  # This service coordinates the entire process from input to final palette output
  class Generator
    attr_reader :brand_input, :options

    # Initialize the generator with brand inputs
    # @param brand_input [Hash] Brand vision details
    # @option brand_input [String] :brand_id Brand identifier
    # @option brand_input [Array<String>] :traits Brand traits (e.g., "innovative", "approachable")
    # @option brand_input [Array<String>] :tone Brand tone (e.g., "confident", "friendly")
    # @option brand_input [Array<String>] :audiences Target audiences (e.g., "prosumer", "SMB")
    # @option brand_input [String] :category Business category (e.g., "SaaS")
    # @option brand_input [Array<String>] :markets Target markets (e.g., "US", "AU")
    # @option brand_input [Array<String>] :keywords Brand keywords (e.g., "automation", "reliability")
    # @param options [Hash] Generation options
    # @option options [Integer] :palette_count Number of palettes to generate (default: 10)
    # @option options [Boolean] :include_dark_mode Generate dark mode variants (default: true)
    def initialize(brand_input, options = {})
      @brand_input = brand_input
      @options = default_options.merge(options)
    end

    # Execute the full palette generation pipeline
    # @return [Hash] Complete generation result with palettes and metadata
    def generate
      # Step 1: NLP Normalization
      normalized_data = normalize_inputs

      # Step 2: Palette Generation (includes emotion-color mapping)
      palettes = generate_palettes(normalized_data)

      # Step 3: Apply Constraints (accessibility, cultural, category)
      constrained_palettes = apply_constraints(palettes)

      # Step 4: Generate mode variations
      final_palettes = generate_variations(constrained_palettes)

      # Build final result
      {
        brand_id: @brand_input[:brand_id],
        palettes: final_palettes,
        metadata: {
          input: @brand_input,
          design_vector: normalized_data[:design_vector],
          descriptors: normalized_data[:descriptors],
          primary_traits: normalized_data[:primary_traits],
          color_hints: normalized_data[:color_hints],
          generated_at: Time.now
        }
      }
    end

    # Generate a single best palette (quick mode)
    # @return [Hash] Single palette result
    def generate_best
      result = generate
      best_palette = result[:palettes].first

      {
        brand_id: @brand_input[:brand_id],
        palette: best_palette,
        metadata: result[:metadata]
      }
    end

    private

    def default_options
      {
        palette_count: 10,
        include_dark_mode: true
      }
    end

    # Step 1: NLP Normalization
    def normalize_inputs
      normalizer = NlpNormalizer.new(@brand_input)
      normalized = normalizer.normalize

      # Add the design vector back to brand_input for constraint layer
      @brand_input[:design_vector] = normalized[:design_vector]

      normalized
    end

    # Step 2: Generate palettes using emotion-color mapping and harmony schemes
    def generate_palettes(normalized_data)
      generator = PaletteGenerator.new(normalized_data)
      generator.generate(count: @options[:palette_count])
    end

    # Step 3: Apply constraints (accessibility, cultural, category)
    def apply_constraints(palettes)
      constraint_layer = ConstraintLayer.new(@brand_input, palettes)
      constraint_layer.apply
    end

    # Step 4: Generate light/dark mode variations
    def generate_variations(palettes)
      palettes.map do |palette|
        if @options[:include_dark_mode]
          constraint_layer = ConstraintLayer.new(@brand_input, [ palette ])
          variations = constraint_layer.generate_mode_variations(palette)

          palette.merge(
            variants: variations
          )
        else
          palette
        end
      end
    end
  end
end
