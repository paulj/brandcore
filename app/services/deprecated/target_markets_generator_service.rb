# frozen_string_literal: true

# Service to generate target markets suggestions using OpenAI
class TargetMarketsGeneratorService
  def initialize(brand_concept:, brand_vision:)
    @brand_concept = brand_concept
    @brand_vision = brand_vision
    @openai_client = nil
  end

  # Generate target markets suggestions
  # @return [Array<String>] Array of geographic markets
  def generate
    return [] if openai_client.nil?
    return [] if @brand_concept.blank? && @brand_vision.category.blank?

    begin
      response = openai_client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "system",
              content: system_prompt
            },
            {
              role: "user",
              content: user_prompt
            }
          ],
          temperature: 0.6,
          response_format: { type: "json_object" }
        }
      )

      content = response.dig("choices", 0, "message", "content")
      parse_response(content)
    rescue StandardError => e
      Rails.logger.error("TargetMarketsGeneratorService: OpenAI API error: #{e.message}")
      []
    end
  end

  private

  def openai_client
    return @openai_client if @openai_client

    api_key = ENV["OPENAI_API_KEY"]
    if api_key&.length&.positive?
      @openai_client = OpenAI::Client.new(access_token: api_key)
    else
      Rails.logger.warn("TargetMarketsGeneratorService: OPENAI_API_KEY not set, generation disabled")
      @openai_client = nil
    end

    @openai_client
  end

  def system_prompt
    <<~PROMPT
      You are a professional brand strategist helping to identify target geographic markets for brands.
      Target markets are the geographic regions where a brand operates or plans to operate.

      Based on the brand information provided, generate 3-5 target market suggestions that:
      1. Are realistic for the brand's stage and category
      2. Use clear geographic descriptors (e.g., "US", "UK", "EU", "Australia", "Southeast Asia", "Global")
      3. Start with most logical/achievable markets first
      4. Consider the brand's audience and category

      IMPORTANT: You must respond with valid JSON only. Use this exact structure:
      {
        "markets": [
          "market1",
          "market2",
          "market3"
        ]
      }
    PROMPT
  end

  def user_prompt
    parts = []

    if @brand_concept.present?
      parts << "Brand Concept:"
      parts << @brand_concept
      parts << ""
    end

    # Include brand vision data if available
    vision_parts = []

    if @brand_vision.mission_statement.present?
      vision_parts << "Mission Statement: #{@brand_vision.mission_statement}"
    end

    if @brand_vision.category.present?
      vision_parts << "Category: #{@brand_vision.category}"
    end

    if @brand_vision.audiences.present? && @brand_vision.audiences.any?
      vision_parts << "Target audiences: #{@brand_vision.audiences.join(', ')}"
    end

    if vision_parts.any?
      parts << "Brand Information:"
      parts << vision_parts.join("\n")
      parts << ""
    end

    parts << "Based on the above, suggest target geographic markets for this brand."
    parts.join("\n")
  end

  def parse_response(content)
    return [] if content.blank?

    data = JSON.parse(content)
    markets = data["markets"] || []

    # Return only valid non-empty strings
    markets.select { |m| m.is_a?(String) && m.present? }
  rescue JSON::ParserError => e
    Rails.logger.error("TargetMarketsGeneratorService: Failed to parse JSON response: #{e.message}")
    []
  end
end
