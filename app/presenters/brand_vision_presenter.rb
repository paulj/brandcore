# frozen_string_literal: true

# BrandVisionPresenter calculates completion status for the Brand Vision section.
# It tracks 6 key brand strategy fields:
# - Mission Statement
# - Vision Statement
# - Core Values (minimum 3 values)
# - Brand Positioning
# - Target Audience
# - Brand Personality
class BrandVisionPresenter
  include SectionProgress

  MIN_CORE_VALUES = 3

  def initialize(brand_vision)
    @brand_vision = brand_vision
  end

  # Total number of completable fields in the Vision section
  # @return [Integer]
  def total_fields
    6
  end

  # Number of completed fields in the Vision section
  # @return [Integer]
  def completed_fields
    count = 0
    count += 1 if mission_statement_complete?
    count += 1 if vision_statement_complete?
    count += 1 if core_values_complete?
    count += 1 if brand_positioning_complete?
    count += 1 if target_audience_complete?
    count += 1 if brand_personality_complete?
    count
  end

  private

  def mission_statement_complete?
    @brand_vision.mission_statement.present?
  end

  def vision_statement_complete?
    @brand_vision.vision_statement.present?
  end

  def core_values_complete?
    @brand_vision.core_values.present? &&
      @brand_vision.core_values.is_a?(Array) &&
      @brand_vision.core_values.size >= MIN_CORE_VALUES
  end

  def brand_positioning_complete?
    @brand_vision.brand_positioning.present?
  end

  def target_audience_complete?
    @brand_vision.target_audience.present?
  end

  def brand_personality_complete?
    @brand_vision.brand_personality.present? &&
      @brand_vision.brand_personality.is_a?(Hash) &&
      @brand_vision.brand_personality.any?
  end
end
