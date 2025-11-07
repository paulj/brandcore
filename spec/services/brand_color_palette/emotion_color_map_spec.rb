# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/services/brand_color_palette/emotion_color_map"

RSpec.describe BrandColorPalette::EmotionColorMap do
  describe ".color_for_trait" do
    it "returns color data for known trait" do
      data = described_class.color_for_trait("innovative")

      expect(data).to be_a(Hash)
      expect(data[:hues]).to be_an(Array)
      expect(data[:families]).to be_an(Array)
      expect(data[:warmth]).to be_a(Numeric)
      expect(data[:saturation]).to be_a(Numeric)
    end

    it "handles case-insensitive input" do
      data = described_class.color_for_trait("INNOVATIVE")

      expect(data).not_to be_nil
      expect(data[:hues]).to be_an(Array)
    end

    it "returns nil for unknown trait" do
      data = described_class.color_for_trait("nonexistent")

      expect(data).to be_nil
    end
  end

  describe ".modifier_for_tone" do
    it "returns modifier data for known tone" do
      modifier = described_class.modifier_for_tone("confident")

      expect(modifier).to be_a(Hash)
      expect(modifier[:lightness_shift]).to be_a(Numeric)
      expect(modifier[:contrast_boost]).to be_a(Numeric)
    end

    it "returns default values for unknown tone" do
      modifier = described_class.modifier_for_tone("unknown")

      expect(modifier[:lightness_shift]).to eq(0.0)
      expect(modifier[:contrast_boost]).to eq(0.0)
    end
  end

  describe ".priors_for_category" do
    it "returns priors for known category" do
      priors = described_class.priors_for_category("SaaS")

      expect(priors).to be_a(Hash)
      expect(priors[:preferred_hues]).to be_an(Array)
      expect(priors[:avoid_hues]).to be_an(Array)
      expect(priors[:warmth_bias]).to be_a(Numeric)
    end

    it "returns defaults for unknown category" do
      priors = described_class.priors_for_category("unknown")

      expect(priors[:preferred_hues]).to eq([])
      expect(priors[:avoid_hues]).to eq([])
      expect(priors[:warmth_bias]).to eq(0.0)
    end
  end
end
