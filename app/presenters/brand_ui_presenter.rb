# frozen_string_literal: true

# BrandUiPresenter calculates completion status for the UI Elements section.
# It tracks completion based on:
# - Button styles defined
# - Form elements defined
# - Spacing system defined
class BrandUiPresenter
  include SectionProgress

  def initialize(brand_ui)
    @brand_ui = brand_ui
  end

  # Total number of completable fields in the UI section
  # @return [Integer]
  def total_fields
    3
  end

  # Number of completed fields in the UI section
  # @return [Integer]
  def completed_fields
    count = 0
    count += 1 if button_styles_complete?
    count += 1 if form_elements_complete?
    count += 1 if spacing_system_complete?
    count
  end

  private

  def button_styles_complete?
    @brand_ui.button_styles.present? &&
      @brand_ui.button_styles.is_a?(Hash) &&
      @brand_ui.button_styles.any?
  end

  def form_elements_complete?
    @brand_ui.form_elements.present? &&
      @brand_ui.form_elements.is_a?(Hash) &&
      @brand_ui.form_elements.any?
  end

  def spacing_system_complete?
    @brand_ui.spacing_system.present? &&
      @brand_ui.spacing_system.is_a?(Hash) &&
      @brand_ui.spacing_system.any?
  end
end
