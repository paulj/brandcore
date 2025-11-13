# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrandColorPalette::Generator do
  let(:brand) do
    Brand.create!(
      name: "ACME Corp",
      slug: "acme"
    )
  end

  let(:brand_input) do
    # Create brand properties as current values
    [ "innovative", "approachable", "premium" ].each do |trait|
      brand.properties.create!(
        property_name: "trait",
        value: { text: trait },
        status: :current,
        accepted_at: Time.current
      )
    end

    [ "confident", "friendly" ].each do |tone_value|
      brand.properties.create!(
        property_name: "tone",
        value: { text: tone_value },
        status: :current,
        accepted_at: Time.current
      )
    end

    [ "prosumer", "SMB" ].each do |audience|
      brand.properties.create!(
        property_name: "audience",
        value: { text: audience },
        status: :current,
        accepted_at: Time.current
      )
    end

    brand.properties.create!(
      property_name: "category",
      value: { text: "SaaS" },
      status: :current,
      accepted_at: Time.current
    )

    [ "US", "AU" ].each do |market|
      brand.properties.create!(
        property_name: "market",
        value: { text: market },
        status: :current,
        accepted_at: Time.current
      )
    end

    [ "automation", "reliability", "speed" ].each do |keyword|
      brand.properties.create!(
        property_name: "keyword",
        value: { text: keyword },
        status: :current,
        accepted_at: Time.current
      )
    end

    brand
  end

  describe "#generate" do
    xit "generates color palettes successfully" do
      generator = described_class.new(brand_input)
      result = generator.generate

      expect(result).to be_a(BrandColorPalette::GeneratorResult)
      expect(result.brand_id).to eq(brand.id)
      expect(result.palettes).to be_an(Array)
      expect(result.metadata).to be_a(BrandColorPalette::GenerationMetadata)
    end

    xit "generates multiple palette candidates" do
      generator = described_class.new(brand_input, palette_count: 5)
      result = generator.generate

      expect(result.palettes.length).to be <= 5
      expect(result.palettes).not_to be_empty
    end

    xit "includes required color roles in each palette" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result.palettes.first
      roles = palette.colors.map(&:role)

      expect(roles).to include("primary")
      expect(roles).to include("background")
      expect(roles).to include("text")
    end

    xit "ensures colors have all required formats" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result.palettes.first
      color = palette.colors.first

      expect(color.oklch).to be_a(BrandColorPalette::OklchColor)
      expect(color.rgb).to be_a(BrandColorPalette::RgbColor)
      expect(color.hex).to be_a(String)
      expect(color.cmyk).to be_a(BrandColorPalette::CmykColor)
    end

    xit "includes accessibility evaluation" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result.palettes.first

      expect(palette.accessibility).to be_a(BrandColorPalette::AccessibilityReport)
      expect(palette.accessibility.valid).not_to be_nil
      expect(palette.accessibility.contrast_ratio).to be_a(Numeric)
    end

    xit "ensures palettes meet WCAG AA standards" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result.palettes.first
      accessibility = palette.accessibility

      expect(accessibility.wcag_aa_normal).to be true
    end

    xit "includes metadata with design vector" do
      generator = described_class.new(brand_input)
      result = generator.generate

      expect(result.metadata.design_vector).to be_a(BrandColorPalette::DesignVector)
      expect(result.metadata.descriptors).to be_an(Array)
      expect(result.metadata.primary_traits).to be_an(Array)
    end

    xit "generates dark mode variants when requested" do
      generator = described_class.new(brand_input, include_dark_mode: true)
      result = generator.generate

      palette = result.palettes.first

      expect(palette.variants).not_to be_nil
      expect(palette.variants[:light]).not_to be_nil
      expect(palette.variants[:dark]).not_to be_nil
    end
  end

  describe "#generate_best" do
    xit "returns a single best palette" do
      generator = described_class.new(brand_input)
      result = generator.generate_best

      expect(result).to be_a(BrandColorPalette::SinglePaletteResult)
      expect(result.brand_id).to eq(brand.id)
      expect(result.palette).to be_a(BrandColorPalette::Palette)
      expect(result.metadata).to be_a(BrandColorPalette::GenerationMetadata)
    end

    xit "returns the highest-scored palette" do
      generator = described_class.new(brand_input)
      full_result = generator.generate
      best_result = generator.generate_best

      expect(best_result.palette.score).to eq(full_result.palettes.first.score)
    end
  end

  describe "palette scoring" do
    xit "scores palettes based on category fit" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palettes = result.palettes
      expect(palettes.first.score).to be_a(Numeric)
      expect(palettes.first.score).to be >= 0
    end

    xit "returns palettes sorted by score" do
      generator = described_class.new(brand_input)
      result = generator.generate

      scores = result.palettes.map(&:score)
      expect(scores).to eq(scores.sort.reverse)
    end
  end

  describe "color format validation" do
    xit "generates valid RGB values" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result.palettes.first
      palette.colors.each do |color|
        expect(color.rgb.r).to be_between(0, 255)
        expect(color.rgb.g).to be_between(0, 255)
        expect(color.rgb.b).to be_between(0, 255)
      end
    end

    xit "generates valid hex codes" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result.palettes.first
      palette.colors.each do |color|
        expect(color.hex).to match(/^#[0-9a-f]{6}$/)
      end
    end

    xit "generates valid OKLCH values" do
      generator = described_class.new(brand_input)
      result = generator.generate

      palette = result.palettes.first
      palette.colors.each do |color|
        expect(color.oklch.l).to be_between(0, 1)
        expect(color.oklch.c).to be >= 0
        expect(color.oklch.h).to be_between(0, 360)
      end
    end
  end
end
