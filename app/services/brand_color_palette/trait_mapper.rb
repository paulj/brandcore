# frozen_string_literal: true

require "json"

module BrandColorPalette
  # Maps arbitrary traits to known traits using OpenAI embeddings
  # Known trait embeddings are cached to disk to avoid API calls
  class TraitMapper
    SIMILARITY_THRESHOLD = 0.75
    CACHE_FILE_PATH = if defined?(Rails)
                        Rails.root.join("lib/data/trait_embeddings.json")
    else
                        File.expand_path("../../../lib/data/trait_embeddings.json", __dir__)
    end
    EMBEDDING_MODEL = "text-embedding-3-small"

    attr_reader :known_traits, :embeddings_cache

    def initialize
      @known_traits = EmotionColorMap::TRAIT_COLOR_MAP.keys
      @embeddings_cache = load_embeddings_cache
      @openai_client = nil
    end

    # Map an arbitrary trait to a known trait
    # @param trait [String] Arbitrary trait name
    # @return [String, nil] Known trait name or nil if no good match
    def map_trait(trait)
      normalized_trait = trait.to_s.downcase.strip

      # Return directly if it's already a known trait
      return normalized_trait if @known_traits.include?(normalized_trait)

      # Get embedding for the arbitrary trait
      trait_embedding = get_embedding(normalized_trait)
      return nil unless trait_embedding

      # Find most similar known trait using cosine similarity
      similarities = @known_traits.map do |known_trait|
        cached_embedding = @embeddings_cache[known_trait]
        next [ known_trait, 0.0 ] unless cached_embedding

        similarity = cosine_similarity(trait_embedding, cached_embedding)
        [ known_trait, similarity ]
      end

      best_match, similarity = similarities.max_by { |_trait, sim| sim }

      # Return match if above threshold
      if similarity >= SIMILARITY_THRESHOLD
        log_info("TraitMapper: Mapped '#{trait}' -> '#{best_match}' (similarity: #{similarity.round(3)})")
        best_match
      else
        log_info("TraitMapper: No match for '#{trait}' (best: '#{best_match}' at #{similarity.round(3)})")
        nil
      end
    end

    # Map multiple traits at once
    # @param traits [Array<String>] Array of trait names
    # @return [Array<String>] Array of known traits (unmapped traits are excluded)
    def map_traits(traits)
      traits.map { |trait| map_trait(trait) }.compact
    end

    private

    def load_embeddings_cache
      if File.exist?(CACHE_FILE_PATH)
        JSON.parse(File.read(CACHE_FILE_PATH))
      else
        log_warn("TraitMapper: Embeddings cache not found at #{CACHE_FILE_PATH}")
        {}
      end
    end

    def get_embedding(text)
      return nil if openai_client.nil?

      # Use simple in-memory cache for this session
      @session_cache ||= {}
      return @session_cache[text] if @session_cache.key?(text)

      begin
        response = openai_client.embeddings(
          parameters: {
            model: EMBEDDING_MODEL,
            input: text
          }
        )

        embedding = response.dig("data", 0, "embedding")
        @session_cache[text] = embedding
        embedding
      rescue StandardError => e
        log_error("TraitMapper: OpenAI API error: #{e.message}")
        nil
      end
    end

    def openai_client
      return @openai_client if @openai_client

      api_key = ENV["OPENAI_API_KEY"]
      if api_key&.length&.positive?
        @openai_client = OpenAI::Client.new(access_token: api_key)
      else
        log_warn("TraitMapper: OPENAI_API_KEY not set, arbitrary trait mapping disabled")
        @openai_client = nil
      end

      @openai_client
    end

    def cosine_similarity(vec_a, vec_b)
      return 0.0 if vec_a.nil? || vec_b.nil?
      return 0.0 if vec_a.length != vec_b.length

      dot_product = vec_a.zip(vec_b).sum { |a, b| a * b }
      magnitude_a = Math.sqrt(vec_a.sum { |a| a**2 })
      magnitude_b = Math.sqrt(vec_b.sum { |b| b**2 })

      return 0.0 if magnitude_a.zero? || magnitude_b.zero?

      dot_product / (magnitude_a * magnitude_b)
    end

    # Safe logging methods that work with or without Rails
    def log_info(message)
      return unless defined?(Rails)

      Rails.logger.info(message)
    end

    def log_warn(message)
      return unless defined?(Rails)

      Rails.logger.warn(message)
    end

    def log_error(message)
      return unless defined?(Rails)

      Rails.logger.error(message)
    end
  end
end
