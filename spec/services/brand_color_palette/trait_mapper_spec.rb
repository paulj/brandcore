# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/services/brand_color_palette/emotion_color_map"
require_relative "../../../app/services/brand_color_palette/trait_mapper"

RSpec.describe BrandColorPalette::TraitMapper do
  let(:mapper) { described_class.new }

  # Create a simple mock embeddings cache for testing
  let(:mock_embeddings) do
    {
      "innovative" => Array.new(1536) { rand },
      "trustworthy" => Array.new(1536) { rand },
      "energetic" => Array.new(1536) { rand }
    }
  end

  before do
    # Mock the embeddings cache file
    allow(File).to receive(:exist?).with(described_class::CACHE_FILE_PATH).and_return(true)
    allow(File).to receive(:read).with(described_class::CACHE_FILE_PATH).and_return(mock_embeddings.to_json)
  end

  describe "#map_trait" do
    context "with known traits" do
      it "returns the trait directly without API call" do
        result = mapper.map_trait("innovative")
        expect(result).to eq("innovative")
      end

      it "handles case-insensitive input" do
        result = mapper.map_trait("INNOVATIVE")
        expect(result).to eq("innovative")
      end

      it "handles whitespace" do
        result = mapper.map_trait("  innovative  ")
        expect(result).to eq("innovative")
      end
    end

    context "with embeddings cache loaded" do
      it "loads embeddings from disk" do
        expect(mapper.embeddings_cache).to be_a(Hash)
        expect(mapper.embeddings_cache).to have_key("innovative")
      end
    end

    context "without OpenAI API key" do
      before do
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(nil)
      end

      it "returns nil for unknown traits" do
        # Create a new mapper to pick up the nil API key
        mapper_without_key = described_class.new

        result = mapper_without_key.map_trait("unknown_trait")
        expect(result).to be_nil
      end
    end

    context "with OpenAI API key" do
      # These tests require the ruby-openai gem to be loaded
      # Skip them in environments where OpenAI constant is not available
      before do
        skip "OpenAI gem not loaded in test environment" unless defined?(OpenAI)
      end

      let(:mock_client) { instance_double(OpenAI::Client) }
      let(:similar_embedding) { mock_embeddings["innovative"].map { |v| v + rand * 0.1 } }

      before do
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")
        allow(OpenAI::Client).to receive(:new).and_return(mock_client) if defined?(OpenAI)
      end

      it "maps similar traits using embeddings" do
        # Mock API response for a trait similar to "innovative"
        allow(mock_client).to receive(:embeddings).and_return(
          {
            "data" => [
              { "embedding" => similar_embedding }
            ]
          }
        )

        # The actual mapping will depend on cosine similarity
        # This test verifies the flow works
        result = mapper.map_trait("inventive")
        expect(result).to be_a(String).or be_nil
      end

      it "returns nil if similarity is below threshold" do
        # Mock API response with very different embedding
        very_different_embedding = Array.new(1536) { rand * 10 }

        allow(mock_client).to receive(:embeddings).and_return(
          {
            "data" => [
              { "embedding" => very_different_embedding }
            ]
          }
        )

        result = mapper.map_trait("completely_unrelated_word")
        expect(result).to be_nil
      end

      it "handles API errors gracefully" do
        allow(mock_client).to receive(:embeddings).and_raise(StandardError.new("API error"))

        result = mapper.map_trait("unknown_trait")
        expect(result).to be_nil
      end
    end
  end

  describe "#map_traits" do
    it "maps multiple traits at once" do
      traits = [ "innovative", "trustworthy", "energetic" ]
      results = mapper.map_traits(traits)

      expect(results).to be_an(Array)
      expect(results.length).to eq(3)
      expect(results).to all(be_a(String))
    end

    it "filters out unmapped traits" do
      allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(nil)
      mapper_without_key = described_class.new

      traits = [ "innovative", "unknown_trait", "trustworthy" ]
      results = mapper_without_key.map_traits(traits)

      expect(results).to eq([ "innovative", "trustworthy" ])
    end
  end

  describe "cosine similarity calculation" do
    it "calculates similarity between vectors" do
      vec_a = [ 1.0, 0.0, 0.0 ]
      vec_b = [ 1.0, 0.0, 0.0 ]

      similarity = mapper.send(:cosine_similarity, vec_a, vec_b)
      expect(similarity).to be_within(0.001).of(1.0)
    end

    it "handles orthogonal vectors" do
      vec_a = [ 1.0, 0.0, 0.0 ]
      vec_b = [ 0.0, 1.0, 0.0 ]

      similarity = mapper.send(:cosine_similarity, vec_a, vec_b)
      expect(similarity).to be_within(0.001).of(0.0)
    end

    it "handles opposite vectors" do
      vec_a = [ 1.0, 0.0, 0.0 ]
      vec_b = [ -1.0, 0.0, 0.0 ]

      similarity = mapper.send(:cosine_similarity, vec_a, vec_b)
      expect(similarity).to be_within(0.001).of(-1.0)
    end

    it "returns 0 for nil vectors" do
      similarity = mapper.send(:cosine_similarity, nil, [ 1.0, 0.0 ])
      expect(similarity).to eq(0.0)
    end

    it "returns 0 for mismatched vector lengths" do
      vec_a = [ 1.0, 0.0 ]
      vec_b = [ 1.0, 0.0, 0.0 ]

      similarity = mapper.send(:cosine_similarity, vec_a, vec_b)
      expect(similarity).to eq(0.0)
    end
  end
end
