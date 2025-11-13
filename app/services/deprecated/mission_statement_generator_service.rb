# frozen_string_literal: true

# Service to generate mission statement candidates using OpenAI based on brand concept
class MissionStatementGeneratorService
  def initialize(brand_concept:, brand_vision:)
    @brand_concept = brand_concept
    @brand_vision = brand_vision
    @openai_client = nil
  end

  # Generate mission statement candidates
  # @return [Array<String>] Array of 3 mission statement candidates
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
          temperature: 0.8,
          response_format: { type: "json_object" }
        }
      )

      content = response.dig("choices", 0, "message", "content")
      parse_response(content)
    rescue StandardError => e
      Rails.logger.error("MissionStatementGeneratorService: OpenAI API error: #{e.message}")
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
      Rails.logger.warn("MissionStatementGeneratorService: OPENAI_API_KEY not set, generation disabled")
      @openai_client = nil
    end

    @openai_client
  end

  def system_prompt
    <<~PROMPT
      You are a professional brand strategist helping to develop mission statements for brands.
      A mission statement defines why a brand exists and what it aims to accomplish in the world.

      Based on the brand concept provided, generate exactly 3 different mission statement candidates that:
      1. Are clear, concise, and compelling (1-2 sentences maximum)
      2. Explain the brand's core purpose and reason for existing
      3. Align with the brand's category, audience, and personality
      4. Are authentic and specific (not generic corporate-speak)
      5. Vary in style and approach to give the user meaningful choices

      The three candidates should offer different perspectives:
      - One focused on the customer/audience benefit
      - One focused on the brand's unique approach or methodology
      - One focused on the broader impact or change the brand seeks to create

      IMPORTANT: You must respond with valid JSON only. Use this exact structure:
      {
        "mission_statements": [
          "First mission statement candidate here.",
          "Second mission statement candidate here.",
          "Third mission statement candidate here."
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

    if @brand_vision.category.present?
      vision_parts << "Category: #{@brand_vision.category}"
    end

    if @brand_vision.audiences.present? && @brand_vision.audiences.any?
      vision_parts << "Target audiences: #{@brand_vision.audiences.join(', ')}"
    end

    if @brand_vision.traits.present? && @brand_vision.traits.any?
      vision_parts << "Brand traits: #{@brand_vision.traits.join(', ')}"
    end

    if @brand_vision.tone.present? && @brand_vision.tone.any?
      vision_parts << "Brand tone: #{@brand_vision.tone.join(', ')}"
    end

    if @brand_vision.keywords.present? && @brand_vision.keywords.any?
      vision_parts << "Key terms: #{@brand_vision.keywords.join(', ')}"
    end

    if vision_parts.any?
      parts << "Additional Brand Information:"
      parts << vision_parts.join("\n")
      parts << ""
    end

    parts << "Based on the above, generate exactly 3 different mission statement candidates."
    parts.join("\n")
  end

  def parse_response(content)
    return [] if content.blank?

    data = JSON.parse(content)
    statements = data["mission_statements"] || []

    # Return only valid non-empty strings, limit to 3
    statements.select { |s| s.is_a?(String) && s.present? }.take(3)
  rescue JSON::ParserError => e
    Rails.logger.error("MissionStatementGeneratorService: Failed to parse JSON response: #{e.message}")
    []
  end
end
