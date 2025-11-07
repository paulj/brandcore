# frozen_string_literal: true

# BrandLogoPresenter calculates completion status for the Logo section.
# It tracks completion based on:
# - Primary logo uploaded
# - Logo philosophy provided
# - Usage guidelines defined
class BrandLogoPresenter
  include SectionProgress

  def initialize(brand_logo)
    @brand_logo = brand_logo
  end

  # Total number of completable fields in the Logo section
  # @return [Integer]
  def total_fields
    3
  end

  # Number of completed fields in the Logo section
  # @return [Integer]
  def completed_fields
    count = 0
    count += 1 if primary_logo_complete?
    count += 1 if logo_philosophy_complete?
    count += 1 if usage_guidelines_complete?
    count
  end

  private

  def primary_logo_complete?
    @brand_logo.primary_logo.attached?
  end

  def logo_philosophy_complete?
    @brand_logo.logo_philosophy.present?
  end

  def usage_guidelines_complete?
    @brand_logo.usage_guidelines.present? &&
      @brand_logo.usage_guidelines.is_a?(Hash) &&
      @brand_logo.usage_guidelines.any?
  end
end

