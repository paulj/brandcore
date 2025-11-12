# frozen_string_literal: true

# Service to generate brand personality suggestions (traits and tone) using OpenAI
class BrandPersonalityGeneratorService
  def initialize(brand_concept:, brand_vision:)
    @brand_concept = brand_concept
    @brand_vision = brand_vision
    @openai_client = nil
  end

  # Generate brand personality suggestions
  # @return [Hash] Hash with :traits and :tone arrays
  def generate
    return { traits: [], tone: [] } if openai_client.nil?
    return { traits: [], tone: [] } if @brand_concept.blank? && @brand_vision.mission_statement.blank?

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
          temperature: 0.8,
          response_format: { type: "json_object" }
        }
      )

      content = response.dig("choices", 0, "message", "content")
      parse_response(content)
    rescue StandardError => e
      Rails.logger.error("BrandPersonalityGeneratorService: OpenAI API error: #{e.message}")
      { traits: [], tone: [] }
    end
  end

  private

  def openai_client
    return @openai_client if @openai_client

    api_key = ENV["OPENAI_API_KEY"]
    if api_key&.length&.positive?
      @openai_client = OpenAI::Client.new(access_token: api_key)
    else
      Rails.logger.warn("BrandPersonalityGeneratorService: OPENAI_API_KEY not set, generation disabled")
      @openai_client = nil
    end

    @openai_client
  end

  def system_prompt
    <<~PROMPT
      You are a professional brand strategist helping to define brand personalities.
      Brand personality consists of traits (characteristics that define the brand's character) and tone (how the brand communicates).

      Based on the brand information provided, generate brand personality suggestions that include:
      1. Traits: 5-7 personality characteristics (e.g., innovative, approachable, professional, bold)
      2. Tone: 5-7 communication descriptors (e.g., confident, friendly, authoritative, conversational)

      The suggestions should:
      - Be specific and actionable (not generic)
      - Align with the brand's mission, vision, category, and audience
      - Create a cohesive and authentic personality
      - Be professional yet memorable

      IMPORTANT: You must respond with valid JSON only. Use this exact structure:
      {
        "traits": [
          "trait1",
          "trait2",
          "trait3",
          "trait4",
          "trait5"
        ],
        "tone": [
          "tone1",
          "tone2",
          "tone3",
          "tone4",
          "tone5"
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

    if @brand_vision.vision_statement.present?
      vision_parts << "Vision Statement: #{@brand_vision.vision_statement}"
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

    parts << "Based on the above, generate brand personality traits and tone suggestions."
    parts.join("\n")
  end

  def parse_response(content)
    return { traits: [], tone: [] } if content.blank?

    data = JSON.parse(content)
    traits = data["traits"] || []
    tone = data["tone"] || []

    {
      traits: traits.select { |t| t.is_a?(String) && t.present? },
      tone: tone.select { |t| t.is_a?(String) && t.present? }
    }
  rescue JSON::ParserError => e
    Rails.logger.error("BrandPersonalityGeneratorService: Failed to parse JSON response: #{e.message}")
    { traits: [], tone: [] }
  end
end
