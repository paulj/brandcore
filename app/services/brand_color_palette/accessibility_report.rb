# frozen_string_literal: true

module BrandColorPalette
  # Accessibility evaluation results
  AccessibilityReport = Struct.new(
    :valid,
    :contrast_ratio,
    :wcag_aa_normal,
    :wcag_aa_large,
    :wcag_aaa_normal,
    :recommendations,
    keyword_init: true
  ) do
    def self.from_hash(hash)
      new(
        valid: hash[:valid],
        contrast_ratio: hash[:contrast_ratio],
        wcag_aa_normal: hash[:wcag_aa_normal],
        wcag_aa_large: hash[:wcag_aa_large],
        wcag_aaa_normal: hash[:wcag_aaa_normal],
        recommendations: hash[:recommendations] || []
      )
    end

    def to_h
      {
        valid: valid,
        contrast_ratio: contrast_ratio,
        wcag_aa_normal: wcag_aa_normal,
        wcag_aa_large: wcag_aa_large,
        wcag_aaa_normal: wcag_aaa_normal,
        recommendations: recommendations
      }
    end
  end
end
