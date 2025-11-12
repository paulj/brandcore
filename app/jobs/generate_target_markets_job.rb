# frozen_string_literal: true

# Background job to generate target markets suggestions using OpenAI
class GenerateTargetMarketsJob < ApplicationJob
  queue_as :default

  def perform(brand_id)
    brand = Brand.find(brand_id)
    brand_vision = brand.brand_vision
    brand_concept = brand.brand_concept&.concept

    generator = TargetMarketsGeneratorService.new(
      brand_concept: brand_concept,
      brand_vision: brand_vision
    )

    markets = generator.generate

    # Broadcast the results via Action Cable
    broadcast_suggestions(brand, markets)
  rescue StandardError => e
    Rails.logger.error("GenerateTargetMarketsJob failed for brand #{brand_id}: #{e.message}")
    broadcast_error(Brand.find(brand_id), e.message)
  end

  private

  def broadcast_suggestions(brand, markets)
    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_vision_#{brand.id}",
      target: "target_markets_suggestions",
      partial: "brand/vision/target_markets_suggestions",
      locals: { markets: markets, brand: brand }
    )
  end

  def broadcast_error(brand, error_message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_vision_#{brand.id}",
      target: "target_markets_suggestions",
      partial: "brand/vision/ai_suggestion_error",
      locals: { error_message: error_message, target_id: "target_markets_suggestions" }
    )
  end
end
