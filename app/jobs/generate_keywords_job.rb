# frozen_string_literal: true

# Background job to generate keywords suggestions using OpenAI
class GenerateKeywordsJob < ApplicationJob
  queue_as :default

  def perform(brand_id)
    brand = Brand.find(brand_id)
    brand_vision = brand.brand_vision
    brand_concept = brand.brand_concept&.concept

    generator = KeywordsGeneratorService.new(
      brand_concept: brand_concept,
      brand_vision: brand_vision
    )

    keywords = generator.generate

    # Broadcast the results via Action Cable
    broadcast_suggestions(brand, keywords)
  rescue StandardError => e
    Rails.logger.error("GenerateKeywordsJob failed for brand #{brand_id}: #{e.message}")
    broadcast_error(Brand.find(brand_id), e.message)
  end

  private

  def broadcast_suggestions(brand, keywords)
    # Reload brand with brand_vision to ensure fresh data in the partial
    brand.reload

    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_vision_#{brand.id}",
      target: "keywords_suggestions",
      partial: "brand/vision/keywords_suggestions",
      locals: { keywords: keywords, brand: brand }
    )
  end

  def broadcast_error(brand, error_message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_vision_#{brand.id}",
      target: "keywords_suggestions",
      partial: "brand/vision/ai_suggestion_error",
      locals: { error_message: error_message, target_id: "keywords_suggestions" }
    )
  end
end
