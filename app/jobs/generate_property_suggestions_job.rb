# frozen_string_literal: true

# Unified background job to generate property suggestions using AI.
# Uses PropertyGeneratorService and broadcasts results via Turbo Streams.
#
# Example usage:
#   GeneratePropertySuggestionsJob.perform_later(brand.id, "mission")
class GeneratePropertySuggestionsJob < ApplicationJob
  queue_as :default

  # Generate suggestions for a property and broadcast via Turbo Streams
  # @param brand_id [Integer] The brand ID
  # @param property_name [String] The property name
  def perform(brand_id, property_name)
    brand = Brand.find(brand_id)
    property_name = property_name.to_s
    configuration = PropertyConfiguration.for(property_name)

    # Broadcast loading state
    broadcast_loading(brand, property_name, configuration)

    # Generate suggestions
    generator = PropertyGeneratorService.new(brand: brand, property_name: property_name)
    suggestions = generator.generate

    if suggestions.any?
      # Save suggestions to database
      suggestions.each(&:save!)

      # Broadcast suggestions to the UI
      broadcast_suggestions(brand, property_name, configuration, suggestions)
    else
      # Broadcast empty state or error
      broadcast_error(brand, property_name, configuration, "No suggestions generated")
    end
  rescue StandardError => e
    Rails.logger.error("GeneratePropertySuggestionsJob: Error generating #{property_name} for brand #{brand_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    # Broadcast error to the UI
    brand = Brand.find_by(id: brand_id)
    configuration = PropertyConfiguration.for(property_name) if brand

    if brand && configuration
      broadcast_error(brand, property_name, configuration, e.message)
    end
  end

  private

  def broadcast_loading(brand, property_name, configuration)
    Turbo::StreamsChannel.broadcast_replace_to(
      property_stream_name(brand, property_name),
      target: "#{property_name}_suggestions",
      partial: "brand/properties/suggestion_loading",
      locals: {
        property_name: property_name,
        configuration: configuration
      }
    )
  end

  def broadcast_suggestions(brand, property_name, configuration, suggestions)
    Turbo::StreamsChannel.broadcast_replace_to(
      property_stream_name(brand, property_name),
      target: "#{property_name}_suggestions",
      partial: "brand/properties/suggestions",
      locals: {
        brand: brand,
        property_name: property_name,
        configuration: configuration,
        suggestions: suggestions
      }
    )
  end

  def broadcast_error(brand, property_name, configuration, error_message)
    Turbo::StreamsChannel.broadcast_replace_to(
      property_stream_name(brand, property_name),
      target: "#{property_name}_suggestions",
      partial: "brand/properties/suggestion_error",
      locals: {
        property_name: property_name,
        configuration: configuration,
        error: error_message
      }
    )
  end

  def property_stream_name(brand, property_name)
    "brand_properties_#{brand.id}"
  end
end
