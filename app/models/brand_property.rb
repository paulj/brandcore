# frozen_string_literal: true

# BrandProperty represents a single property value for a brand with its status lifecycle.
# Properties can be current values, previous values, AI-generated suggestions, or rejected suggestions.
#
# Status lifecycle:
# - suggestion: AI-generated suggestion waiting for user review
# - current: Active value being used
# - previous: Former current value (replaced by a new current value)
# - rejected_suggestion: Suggestion that was explicitly rejected or superseded
#
# Property types support different cardinalities:
# - Single: Only one property can be current at a time (e.g., mission, vision)
# - Multiple: Multiple properties can be current simultaneously (e.g., keywords, markets)
class BrandProperty < ApplicationRecord
  belongs_to :brand

  # Property status enum
  enum :status, {
    suggestion: "suggestion",
    current: "current",
    previous: "previous",
    rejected_suggestion: "rejected_suggestion"
  }, validate: true

  # Validations
  validates :property_name, presence: true
  validates :value, presence: true
  validates :status, presence: true

  # Scopes
  scope :for_property, ->(name) { where(property_name: name) }
  scope :current, -> { where(status: :current) }
  scope :suggestions, -> { where(status: :suggestion) }
  scope :previous, -> { where(status: :previous).order(accepted_at: :desc) }
  scope :by_property, -> { order(:property_name, :created_at) }

  # PaperTrail versioning
  has_paper_trail

  # Accept this suggestion as the current value
  # For single-cardinality properties, this will replace the current value
  # For multiple-cardinality properties, this will add to the current values
  def accept!(cardinality: :single)
    transaction do
      if cardinality == :single
        # Move current to previous
        brand.properties
          .for_property(property_name)
          .current
          .update_all(status: :previous)

        # Reject other suggestions
        brand.properties
          .for_property(property_name)
          .suggestions
          .where.not(id: id)
          .update_all(status: :rejected_suggestion)
      end

      # Make this the current value
      update!(
        status: :current,
        accepted_at: Time.current
      )
    end
  end

  # Reject this suggestion
  def reject!
    update!(status: :rejected_suggestion) if suggestion?
  end

  # Get the property configuration
  def configuration
    @configuration ||= PropertyConfiguration.for(property_name)
  end

  # Get the display label from i18n
  def label
    I18n.t("brand_properties.#{property_name}.label", default: property_name.titleize)
  end

  # Get the display description from i18n
  def description
    I18n.t("brand_properties.#{property_name}.description", default: "")
  end

  # Extract the text value for display
  # Handles both simple strings and structured JSONB
  def text_value
    case value
    when String
      value
    when Hash
      value["text"] || value["name"] || value.values.first
    when Array
      value.first.is_a?(String) ? value.join(", ") : value.map { |v| v["name"] || v["text"] || v.to_s }.join(", ")
    else
      value.to_s
    end
  end
end
