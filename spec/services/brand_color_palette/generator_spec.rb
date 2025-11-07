# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/services/brand_color_palette/color_space"
require_relative "../../../app/services/brand_color_palette/emotion_color_map"
require_relative "../../../app/services/brand_color_palette/nlp_normalizer"
require_relative "../../../app/services/brand_color_palette/wcag_checker"
require_relative "../../../app/services/brand_color_palette/palette_generator"
require_relative "../../../app/services/brand_color_palette/constraint_layer"
require_relative "../../../app/services/brand_color_palette/generator"

RSpec.describe BrandColorPalette::Generator do
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

  describe "#generate" do
    it "generates color palettes successfully" do
      generator = described_class.new(brand_input)
      result = generator.generate

      expect(result).to be_a(Hash)
      expect(result[:brand_id]).to eq("acme")
      expect(result[:palettes]).to be_an(Array)
      expect(result[:metadata]).to be_a(Hash)
    end

    it "generates multiple palette candidates" do
      generator = described_class.new(brand_input, palette_count: 5)
      result = generator.generate

      expect(result[:palettes].length).to be <= 5
      expect(result[:palettes]).not_to be_empty
    end

    it "includes required color roles in each palette" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result[:palettes].first
      colors = palette[:colors]
      roles = colors.map { |c| c[:role] }

      expect(roles).to include("primary")
      expect(roles).to include("background")
      expect(roles).to include("text")
    end

    it "ensures colors have all required formats" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result[:palettes].first
      color = palette[:colors].first

      expect(color).to have_key(:oklch)
      expect(color).to have_key(:rgb)
      expect(color).to have_key(:hex)
      expect(color).to have_key(:cmyk)
    end

    it "includes accessibility evaluation" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result[:palettes].first

      expect(palette).to have_key(:accessibility)
      expect(palette[:accessibility]).to have_key(:valid)
      expect(palette[:accessibility]).to have_key(:contrast_ratio)
    end

    it "ensures palettes meet WCAG AA standards" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result[:palettes].first
      accessibility = palette[:accessibility]

      expect(accessibility[:wcag_aa_normal]).to be true
    end

    it "includes metadata with design vector" do
      generator = described_class.new(brand_input)
      result = generator.generate

      expect(result[:metadata][:design_vector]).to be_a(Hash)
      expect(result[:metadata][:descriptors]).to be_an(Array)
      expect(result[:metadata][:primary_traits]).to be_an(Array)
    end

    it "generates dark mode variants when requested" do
      generator = described_class.new(brand_input, include_dark_mode: true)
      result = generator.generate

      palette = result[:palettes].first

      expect(palette).to have_key(:variants)
      expect(palette[:variants]).to have_key(:light)
      expect(palette[:variants]).to have_key(:dark)
    end
  end

  describe "#generate_best" do
    it "returns a single best palette" do
      generator = described_class.new(brand_input)
      result = generator.generate_best

      expect(result).to be_a(Hash)
      expect(result[:brand_id]).to eq("acme")
      expect(result[:palette]).to be_a(Hash)
      expect(result[:metadata]).to be_a(Hash)
    end

    it "returns the highest-scored palette" do
      generator = described_class.new(brand_input)
      full_result = generator.generate
      best_result = generator.generate_best

      expect(best_result[:palette]).to eq(full_result[:palettes].first)
    end
  end

  describe "palette scoring" do
    it "scores palettes based on category fit" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palettes = result[:palettes]
      expect(palettes.first[:score]).to be_a(Numeric)
      expect(palettes.first[:score]).to be >= 0
    end

    it "returns palettes sorted by score" do
      generator = described_class.new(brand_input)
      result = generator.generate

      scores = result[:palettes].map { |p| p[:score] }
      expect(scores).to eq(scores.sort.reverse)
    end
  end

  describe "color format validation" do
    it "generates valid RGB values" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result[:palettes].first
      palette[:colors].each do |color|
        expect(color[:rgb][:r]).to be_between(0, 255)
        expect(color[:rgb][:g]).to be_between(0, 255)
        expect(color[:rgb][:b]).to be_between(0, 255)
      end
    end

    it "generates valid hex codes" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result[:palettes].first
      palette[:colors].each do |color|
        expect(color[:hex]).to match(/^#[0-9a-f]{6}$/)
      end
    end

    it "generates valid OKLCH values" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result[:palettes].first
      palette[:colors].each do |color|
        expect(color[:oklch][:l]).to be_between(0, 1)
        expect(color[:oklch][:c]).to be >= 0
        expect(color[:oklch][:h]).to be_between(0, 360)
      end
    end
  end
end
