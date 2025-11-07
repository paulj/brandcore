# frozen_string_literal: true

# BrandTypographyPresenter calculates completion status for the Typography section.
# It tracks completion based on:
# - Scheme selected
# - All required typefaces for the scheme are defined
# - Type scale defined for at least one typeface
# - Usage guidelines provided
class BrandTypographyPresenter
  include SectionProgress

  def initialize(brand_typography)
    @brand_typography = brand_typography
  end

  # Total number of completable fields in the Typography section
  # @return [Integer]
  def total_fields
    4
  end

  # Number of completed fields in the Typography section
  # @return [Integer]
  def completed_fields
    count = 0
    count += 1 if scheme_complete?
    count += 1 if typefaces_complete?
    count += 1 if type_scale_complete?
    count += 1 if usage_guidelines_complete?
    count
  end

  private

  def scheme_complete?
    @brand_typography.scheme.present?
  end

  def typefaces_complete?
    return false unless scheme_complete?
    @brand_typography.scheme_complete?
  end

  def type_scale_complete?
    @brand_typography.typefaces.any? do |typeface|
      typeface.type_scale.present? &&
        typeface.type_scale.is_a?(Hash) &&
        typeface.type_scale.any?
    end
  end

  def usage_guidelines_complete?
    @brand_typography.usage_guidelines.present?
  end
end
