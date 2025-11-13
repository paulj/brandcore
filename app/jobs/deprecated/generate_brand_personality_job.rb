# frozen_string_literal: true

# Background job to generate brand personality suggestions using OpenAI
class GenerateBrandPersonalityJob < ApplicationJob
  queue_as :default

  def perform(brand_id)
    brand = Brand.find(brand_id)
    brand_vision = brand.brand_vision
    brand_concept = brand.brand_concept&.concept

    generator = BrandPersonalityGeneratorService.new(
      brand_concept: brand_concept,
      brand_vision: brand_vision
    )

    personality = generator.generate

    # Broadcast the results via Action Cable
    broadcast_suggestions(brand, personality)
  rescue StandardError => e
    Rails.logger.error("GenerateBrandPersonalityJob failed for brand #{brand_id}: #{e.message}")
    broadcast_error(Brand.find(brand_id), e.message)
  end

  private

  def broadcast_suggestions(brand, personality)
    # Reload brand with brand_vision to ensure fresh data in the partial
    brand.reload

    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_vision_#{brand.id}",
      target: "brand_personality_suggestions",
      partial: "brand/vision/brand_personality_suggestions",
      locals: { traits: personality[:traits], tone: personality[:tone], brand: brand }
    )
  end

  def broadcast_error(brand, error_message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_vision_#{brand.id}",
      target: "brand_personality_suggestions",
      partial: "brand/vision/ai_suggestion_error",
      locals: { error_message: error_message, target_id: "brand_personality_suggestions" }
    )
  end
end
