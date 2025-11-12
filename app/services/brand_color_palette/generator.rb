# frozen_string_literal: true

module BrandColorPalette
  # Main orchestrator for the brand color palette generation pipeline
  # This service coordinates the entire process from input to final palette output
  class Generator
    attr_reader :brand_input, :options

    # Initialize the generator with brand inputs
    # @param brand_input [BrandVision] Brand vision details (BrandVision model)
    # @param options [Hash] Generation options
    # @option options [Integer] :palette_count Number of palettes to generate (default: 10)
    # @option options [Boolean] :include_dark_mode Generate dark mode variants (default: true)
    def initialize(brand_input, options = {})
      raise ArgumentError, "brand_input must be a BrandVision model" unless brand_input.is_a?(BrandVision)

      @brand_input = brand_input
      @brand_input_hash = brand_input.to_h
      @options = default_options.merge(options)
    end

    # Execute the full palette generation pipeline
    # @return [GeneratorResult] Complete generation result with palettes and metadata
    def generate
      # Step 1: NLP Normalization
      normalized_data = normalize_nlp

      # Step 2: Palette Generation (includes emotion-color mapping)
      palettes = generate_palettes(normalized_data)

      # Step 3: Apply Constraints (accessibility, cultural, category)
      constrained_palettes = apply_constraints(palettes)

      # Step 4: Generate mode variations
      final_palettes = generate_variations(constrained_palettes)

      # Build final result as struct
      GeneratorResult.new(
        brand_id: @brand_input.brand_id,
        palettes: final_palettes.map { |p| Palette.from_hash(p) },
        metadata: GenerationMetadata.new(
          input: @brand_input,
          design_vector: DesignVector.from_hash(normalized_data[:design_vector]),
          descriptors: normalized_data[:descriptors],
          primary_traits: normalized_data[:primary_traits],
          color_hints: normalized_data[:color_hints],
          mapped_traits: normalized_data[:mapped_traits].map { |m| TraitMapping.new(**m) },
          generated_at: Time.now
        )
      )
    end

    # Generate a single best palette (quick mode)
    # @return [SinglePaletteResult] Single palette result
    def generate_best
      result = generate

      SinglePaletteResult.new(
        brand_id: result.brand_id,
        palette: result.best_palette,
        metadata: result.metadata
      )
    end

    private

    def default_options
      {
        palette_count: 10,
        include_dark_mode: true
      }
    end

    # Step 1: NLP Normalization
    def normalize_nlp
      normalizer = NlpNormalizer.new(@brand_input_hash)
      normalized = normalizer.normalize

      # Add the design vector back to brand_input_hash for constraint layer
      @brand_input_hash[:design_vector] = normalized[:design_vector]

      normalized
    end

    # Step 2: Generate palettes using emotion-color mapping and harmony schemes
    def generate_palettes(normalized_data)
      generator = PaletteGenerator.new(normalized_data)
      generator.generate(count: @options[:palette_count])
    end

    # Step 3: Apply constraints (accessibility, cultural, category)
    def apply_constraints(palettes)
      constraint_layer = ConstraintLayer.new(@brand_input_hash, palettes)
      constraint_layer.apply
    end

    # Step 4: Generate light/dark mode variations
    def generate_variations(palettes)
      palettes.map do |palette|
        if @options[:include_dark_mode]
          constraint_layer = ConstraintLayer.new(@brand_input_hash, [ palette ])
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
