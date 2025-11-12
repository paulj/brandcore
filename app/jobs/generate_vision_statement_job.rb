# frozen_string_literal: true

# Background job to generate vision statement candidates using OpenAI
class GenerateVisionStatementJob < ApplicationJob
  queue_as :default

  def perform(brand_id)
    brand = Brand.find(brand_id)
    brand_vision = brand.brand_vision
    brand_concept = brand.brand_concept&.concept

    generator = VisionStatementGeneratorService.new(
      brand_concept: brand_concept,
      brand_vision: brand_vision
    )

    candidates = generator.generate

    # Persist suggestions to database
    suggestions = persist_suggestions(brand_vision, candidates)

    # Broadcast the results via Action Cable
    broadcast_suggestions(brand, suggestions)
  rescue StandardError => e
    Rails.logger.error("GenerateVisionStatementJob failed for brand #{brand_id}: #{e.message}")
    broadcast_error(Brand.find(brand_id), e.message)
  end

  private

  def persist_suggestions(brand_vision, candidates)
    candidates.map do |candidate|
      brand_vision.suggestions.create!(
        field_name: "vision_statement",
        content: { text: candidate },
        status: :pending
      )
    end
  end

  def broadcast_suggestions(brand, suggestions)
    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_vision_#{brand.id}",
      target: "vision_statement_suggestions",
      partial: "brand/vision/vision_statement_suggestions",
      locals: { suggestions: suggestions, brand: brand }
    )
  end

  def broadcast_error(brand, error_message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_vision_#{brand.id}",
      target: "vision_statement_suggestions",
      partial: "brand/vision/ai_suggestion_error",
      locals: { error_message: error_message, target_id: "vision_statement_suggestions" }
    )
  end
end
