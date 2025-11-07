# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/services/brand_color_palette/emotion_color_map"
require_relative "../../../app/services/brand_color_palette/trait_mapper"
require_relative "../../../app/services/brand_color_palette/nlp_normalizer"

RSpec.describe BrandColorPalette::NlpNormalizer do
  let(:brand_input) do
    {
      brand_id: "acme",
      traits: [ "innovative", "approachable", "premium" ],
      tone: [ "confident", "friendly" ],
      audiences: [ "prosumer", "SMB" ],
      category: "SaaS",
      markets: [ "US", "AU" ],
      keywords: [ "automation", "reliability", "speed" ]
    }
  end

  describe "#normalize" do
    it "returns normalized data with design vector" do
      normalizer = described_class.new(brand_input)
      result = normalizer.normalize

      expect(result).to have_key(:design_vector)
      expect(result).to have_key(:descriptors)
      expect(result).to have_key(:primary_traits)
      expect(result).to have_key(:color_hints)
      expect(result).to have_key(:mapped_traits)
    end

    it "computes design vector with valid ranges" do
      normalizer = described_class.new(brand_input)
      result = normalizer.normalize
      vector = result[:design_vector]

      described_class::DESIGN_AXES.each_key do |axis|
        expect(vector[axis]).to be_between(-1.0, 1.0)
      end
    end

    it "extracts descriptors based on design vector" do
      normalizer = described_class.new(brand_input)
      result = normalizer.normalize

      expect(result[:descriptors]).to be_an(Array)
    end

    it "extracts primary traits" do
      normalizer = described_class.new(brand_input)
      result = normalizer.normalize

      expect(result[:primary_traits]).to eq([ "innovative", "approachable", "premium" ])
    end

    it "extracts color hints from traits" do
      normalizer = described_class.new(brand_input)
      result = normalizer.normalize

      expect(result[:color_hints]).to be_an(Array)
      expect(result[:color_hints]).not_to be_empty
    end
  end

  describe "design vector calculation" do
    it "adjusts warmth based on traits" do
      warm_input = { traits: [ "friendly", "warm" ] }
      cool_input = { traits: [ "professional", "trustworthy" ] }

      warm_result = described_class.new(warm_input).normalize
      cool_result = described_class.new(cool_input).normalize

      expect(warm_result[:design_vector][:warmth]).to be > cool_result[:design_vector][:warmth]
    end

    it "adjusts modernity based on keywords" do
      modern_input = { keywords: [ "innovation", "automation" ] }
      result = described_class.new(modern_input).normalize

      expect(result[:design_vector][:modernity]).to be > 0
    end
  end

  describe "trait mapping" do
    let(:mock_trait_mapper) { instance_double(BrandColorPalette::TraitMapper) }

    it "maps unknown traits using trait mapper" do
      input_with_unknown = { traits: [ "inventive" ] }

      # Mock trait mapper to map "inventive" -> "innovative"
      allow(mock_trait_mapper).to receive(:map_trait).with("inventive").and_return("innovative")

      normalizer = described_class.new(input_with_unknown, trait_mapper: mock_trait_mapper)
      result = normalizer.normalize

      expect(result[:mapped_traits]).not_to be_empty
      expect(result[:mapped_traits].first[:original]).to eq("inventive")
      expect(result[:mapped_traits].first[:mapped]).to eq("innovative")
    end

    it "does not map known traits" do
      normalizer = described_class.new(brand_input)
      result = normalizer.normalize

      # All traits are known, so no mappings should occur
      expect(result[:mapped_traits]).to be_empty
    end

    it "includes mapped traits in color hints" do
      input_with_unknown = { traits: [ "inventive" ] }

      # Mock trait mapper
      allow(mock_trait_mapper).to receive(:map_trait).with("inventive").and_return("innovative")

      normalizer = described_class.new(input_with_unknown, trait_mapper: mock_trait_mapper)
      result = normalizer.normalize

      # Should include color hints from the mapped trait
      expect(result[:color_hints]).not_to be_empty
    end
  end
end
