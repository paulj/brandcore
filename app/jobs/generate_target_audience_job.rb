# frozen_string_literal: true

# Background job to generate target audience suggestions using OpenAI
class GenerateTargetAudienceJob < ApplicationJob
  queue_as :default

  def perform(brand_id)
    brand = Brand.find(brand_id)
    brand_vision = brand.brand_vision
    brand_concept = brand.brand_concept&.concept

    generator = TargetAudienceGeneratorService.new(
      brand_concept: brand_concept,
      brand_vision: brand_vision
    )

    audiences = generator.generate

    # Persist suggestions to database
    suggestion = persist_suggestion(brand_vision, audiences)

    # Broadcast the results via Action Cable
    broadcast_suggestions(brand, suggestion)
  rescue StandardError => e
    Rails.logger.error("GenerateTargetAudienceJob failed for brand #{brand_id}: #{e.message}")
    broadcast_error(Brand.find(brand_id), e.message)
  end

  private

  def persist_suggestion(brand_vision, audiences)
    brand_vision.suggestions.create!(
      field_name: "target_audience",
      content: { audiences: audiences },
      status: :pending
    )
  end

  def broadcast_suggestions(brand, suggestion)
    # Reload brand with brand_vision to ensure fresh data in the partial
    brand.reload

    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_vision_#{brand.id}",
      target: "target_audience_suggestions",
      partial: "brand/vision/target_audience_suggestions",
      locals: { suggestion: suggestion, brand: brand }
    )
  end

  def broadcast_error(brand, error_message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_vision_#{brand.id}",
      target: "target_audience_suggestions",
      partial: "brand/vision/ai_suggestion_error",
      locals: { error_message: error_message, target_id: "target_audience_suggestions" }
    )
  end
end
