# frozen_string_literal: true

# Service to generate category suggestions using OpenAI
class CategorySuggestionGeneratorService
  def initialize(brand_concept:, brand_vision:)
    @brand_concept = brand_concept
    @brand_vision = brand_vision
    @openai_client = nil
  end

  # Generate category suggestion
  # @return [String] A single category suggestion
  def generate
    return "" if openai_client.nil?
    return "" if @brand_concept.blank? && @brand_vision.mission_statement.blank?

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
          temperature: 0.5,
          response_format: { type: "json_object" }
        }
      )

      content = response.dig("choices", 0, "message", "content")
      parse_response(content)
    rescue StandardError => e
      Rails.logger.error("CategorySuggestionGeneratorService: OpenAI API error: #{e.message}")
      ""
    end
  end

  private

  def openai_client
    return @openai_client if @openai_client

    api_key = ENV["OPENAI_API_KEY"]
    if api_key&.length&.positive?
      @openai_client = OpenAI::Client.new(access_token: api_key)
    else
      Rails.logger.warn("CategorySuggestionGeneratorService: OPENAI_API_KEY not set, generation disabled")
      @openai_client = nil
    end

    @openai_client
  end

  def system_prompt
    <<~PROMPT
      You are a professional brand strategist helping to categorize brands.

      Based on the brand information provided, suggest the most appropriate category from this list:
      - SaaS
      - E-commerce
      - Fintech
      - Healthcare
      - Education
      - Food & Beverage
      - Fashion & Apparel
      - Technology
      - Consulting
      - Non-profit
      - Other

      Choose the single best match based on the brand's mission, vision, and concept.
      If none fit perfectly, choose "Other".

      IMPORTANT: You must respond with valid JSON only. Use this exact structure:
      {
        "category": "the category name here"
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

    if @brand_vision.vision_statement.present?
      vision_parts << "Vision Statement: #{@brand_vision.vision_statement}"
    end

    if vision_parts.any?
      parts << "Brand Information:"
      parts << vision_parts.join("\n")
      parts << ""
    end

    parts << "Based on the above, suggest the most appropriate category for this brand."
    parts.join("\n")
  end

  def parse_response(content)
    return "" if content.blank?

    data = JSON.parse(content)
    category = data["category"]

    category.is_a?(String) && category.present? ? category : ""
  rescue JSON::ParserError => e
    Rails.logger.error("CategorySuggestionGeneratorService: Failed to parse JSON response: #{e.message}")
    ""
  end
end
