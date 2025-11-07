# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/services/brand_color_palette/color_space"

RSpec.describe BrandColorPalette::ColorSpace do
  describe ".oklch_to_srgb" do
    it "converts OKLCH to RGB correctly" do
      # Test a mid-blue color
      rgb = described_class.oklch_to_srgb(0.5, 0.15, 220)

      expect(rgb[:r]).to be_between(0, 255)
      expect(rgb[:g]).to be_between(0, 255)
      expect(rgb[:b]).to be_between(0, 255)
    end

    it "handles edge cases - black" do
      rgb = described_class.oklch_to_srgb(0.0, 0.0, 0)

      expect(rgb[:r]).to eq(0)
      expect(rgb[:g]).to eq(0)
      expect(rgb[:b]).to eq(0)
    end

    it "handles edge cases - white" do
      rgb = described_class.oklch_to_srgb(1.0, 0.0, 0)

      expect(rgb[:r]).to eq(255)
      expect(rgb[:g]).to eq(255)
      expect(rgb[:b]).to eq(255)
    end
  end

  describe ".srgb_to_oklch" do
    it "converts RGB to OKLCH correctly" do
      oklch = described_class.srgb_to_oklch(100, 150, 200)

      expect(oklch[:l]).to be_between(0, 1)
      expect(oklch[:c]).to be >= 0
      expect(oklch[:h]).to be_between(0, 360)
    end

    it "round-trips correctly" do
      original_rgb = { r: 120, g: 180, b: 220 }
      oklch = described_class.srgb_to_oklch(original_rgb[:r], original_rgb[:g], original_rgb[:b])
      converted_rgb = described_class.oklch_to_srgb(oklch[:l], oklch[:c], oklch[:h])

      # Allow small rounding errors
      expect(converted_rgb[:r]).to be_within(2).of(original_rgb[:r])
      expect(converted_rgb[:g]).to be_within(2).of(original_rgb[:g])
      expect(converted_rgb[:b]).to be_within(2).of(original_rgb[:b])
    end
  end

  describe ".rgb_to_hex" do
    it "converts RGB to hex format" do
      hex = described_class.rgb_to_hex(255, 128, 64)
      expect(hex).to eq("#ff8040")
    end
  end

  describe ".hex_to_rgb" do
    it "converts hex to RGB" do
      rgb = described_class.hex_to_rgb("#ff8040")
      expect(rgb).to eq({ r: 255, g: 128, b: 64 })
    end

    it "handles hex without # prefix" do
      rgb = described_class.hex_to_rgb("ff8040")
      expect(rgb).to eq({ r: 255, g: 128, b: 64 })
    end
  end

  describe ".rgb_to_cmyk" do
    it "converts RGB to CMYK" do
      cmyk = described_class.rgb_to_cmyk(255, 0, 0)
      expect(cmyk[:c]).to eq(0)
      expect(cmyk[:m]).to eq(100)
      expect(cmyk[:y]).to eq(100)
      expect(cmyk[:k]).to eq(0)
    end

    it "handles black color" do
      cmyk = described_class.rgb_to_cmyk(0, 0, 0)
      expect(cmyk).to eq({ c: 0, m: 0, y: 0, k: 100 })
    end
  end
end
