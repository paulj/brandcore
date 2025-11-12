# frozen_string_literal: true

# Background job to generate category suggestion using OpenAI
class GenerateCategorySuggestionJob < ApplicationJob
  queue_as :default

  def perform(brand_id)
    brand = Brand.find(brand_id)
    brand_vision = brand.brand_vision
    brand_concept = brand.brand_concept&.concept

    generator = CategorySuggestionGeneratorService.new(
      brand_concept: brand_concept,
      brand_vision: brand_vision
    )

    category = generator.generate

    # Persist suggestions to database
    suggestion = persist_suggestion(brand_vision, category)

    # Broadcast the result via Action Cable
    broadcast_suggestion(brand, suggestion)
  rescue StandardError => e
    Rails.logger.error("GenerateCategorySuggestionJob failed for brand #{brand_id}: #{e.message}")
    broadcast_error(Brand.find(brand_id), e.message)
  end

  private

  def persist_suggestion(brand_vision, category)
    brand_vision.suggestions.create!(
      field_name: "category",
      content: { text: category },
      status: :pending
    )
  end

  def broadcast_suggestion(brand, suggestion)
    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_vision_#{brand.id}",
      target: "category_suggestions",
      partial: "brand/vision/category_suggestions",
      locals: { suggestion: suggestion, brand: brand }
    )
  end

  def broadcast_error(brand, error_message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_vision_#{brand.id}",
      target: "category_suggestions",
      partial: "brand/vision/ai_suggestion_error",
      locals: { error_message: error_message, target_id: "category_suggestions" }
    )
  end
end
