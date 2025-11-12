# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/services/brand_color_palette/color_space"
require_relative "../../../app/services/brand_color_palette/wcag_checker"

RSpec.describe BrandColorPalette::WcagChecker do
  describe ".contrast_ratio" do
    it "calculates contrast ratio for black and white" do
      black = { r: 0, g: 0, b: 0 }
      white = { r: 255, g: 255, b: 255 }

      ratio = described_class.contrast_ratio(black, white)
      expect(ratio).to be_within(0.1).of(21.0)
    end

    it "calculates contrast ratio for similar colors" do
      gray1 = { r: 100, g: 100, b: 100 }
      gray2 = { r: 120, g: 120, b: 120 }

      ratio = described_class.contrast_ratio(gray1, gray2)
      expect(ratio).to be < 2.0
    end
  end

  describe ".meets_aa_normal?" do
    it "returns true for sufficient contrast" do
      text = { r: 0, g: 0, b: 0 }
      background = { r: 255, g: 255, b: 255 }

      expect(described_class.meets_aa_normal?(text, background)).to be true
    end

    it "returns false for insufficient contrast" do
      text = { r: 170, g: 170, b: 170 }
      background = { r: 200, g: 200, b: 200 }

      expect(described_class.meets_aa_normal?(text, background)).to be false
    end
  end

  describe ".evaluate_palette" do
    it "evaluates a palette with good contrast" do
      palette = {
        colors: [
          { role: "background", rgb: { r: 255, g: 255, b: 255 } },
          { role: "text", rgb: { r: 0, g: 0, b: 0 } }
        ]
      }

      result = described_class.evaluate_palette(palette)

      expect(result[:valid]).to be true
      expect(result[:wcag_aa_normal]).to be true
      expect(result[:contrast_ratio]).to be > 4.5
    end

    it "identifies insufficient contrast" do
      palette = {
        colors: [
          { role: "background", rgb: { r: 200, g: 200, b: 200 } },
          { role: "text", rgb: { r: 180, g: 180, b: 180 } }
        ]
      }

      result = described_class.evaluate_palette(palette)

      expect(result[:valid]).to be false
      expect(result[:wcag_aa_normal]).to be false
    end
  end

  describe ".adjust_for_contrast" do
    it "adjusts lightness to meet contrast requirements" do
      color_oklch = { l: 0.7, c: 0.1, h: 220 }
      target_rgb = { r: 255, g: 255, b: 255 }

      adjusted = described_class.adjust_for_contrast(color_oklch, target_rgb)

      # Verify it now meets contrast
      rgb = BrandColorPalette::ColorSpace.oklch_to_srgb(adjusted[:l], adjusted[:c], adjusted[:h])
      ratio = described_class.contrast_ratio(rgb, target_rgb)
      expect(ratio).to be >= described_class::WCAG_AA_NORMAL

      # Should have been adjusted (darkened for white background)
      expect(adjusted[:l]).not_to eq(color_oklch[:l])
    end
  end
end
