# frozen_string_literal: true

# BrandTypographyPresenter calculates completion status for the Typography section.
# It tracks completion based on:
# - Primary typeface defined
# - Type scale defined
# - Usage guidelines provided
class BrandTypographyPresenter
  include SectionProgress

  def initialize(brand_typography)
    @brand_typography = brand_typography
  end

  # Total number of completable fields in the Typography section
  # @return [Integer]
  def total_fields
    3
  end

  # Number of completed fields in the Typography section
  # @return [Integer]
  def completed_fields
    count = 0
    count += 1 if primary_typeface_complete?
    count += 1 if type_scale_complete?
    count += 1 if usage_guidelines_complete?
    count
  end

  private

  def primary_typeface_complete?
    @brand_typography.primary_typeface.present? &&
      @brand_typography.primary_typeface.is_a?(Hash) &&
      @brand_typography.primary_typeface['name'].present?
  end

  def type_scale_complete?
    @brand_typography.type_scale.present? &&
      @brand_typography.type_scale.is_a?(Hash) &&
      @brand_typography.type_scale.any?
  end

  def usage_guidelines_complete?
    @brand_typography.usage_guidelines.present?
  end
end

