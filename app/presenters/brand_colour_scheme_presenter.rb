# frozen_string_literal: true

# BrandColourSchemePresenter calculates completion status for the Colour Scheme section.
# It tracks completion based on:
# - Having at least one palette colour
# - Having token assignments for key semantic roles
# - Usage guidelines provided
class BrandColourSchemePresenter
  include SectionProgress

  REQUIRED_TOKEN_ROLES = %w[surface-base content-primary interactive-primary].freeze

  def initialize(brand_colour_scheme)
    @brand_colour_scheme = brand_colour_scheme
  end

  # Total number of completable fields in the Colour Scheme section
  # @return [Integer]
  def total_fields
    3
  end

  # Number of completed fields in the Colour Scheme section
  # @return [Integer]
  def completed_fields
    count = 0
    count += 1 if palette_colours_complete?
    count += 1 if token_assignments_complete?
    count += 1 if usage_guidelines_complete?
    count
  end

  private

  def palette_colours_complete?
    @brand_colour_scheme.palette_colours.any?
  end

  def token_assignments_complete?
    assigned_roles = @brand_colour_scheme.token_assignments.pluck(:token_role)
    REQUIRED_TOKEN_ROLES.all? { |role| assigned_roles.include?(role) }
  end

  def usage_guidelines_complete?
    @brand_colour_scheme.usage_guidelines.present?
  end
end

