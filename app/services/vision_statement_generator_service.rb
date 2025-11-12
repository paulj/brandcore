# frozen_string_literal: true

# Service to generate vision statement candidates using OpenAI
class VisionStatementGeneratorService
  def initialize(brand_concept:, brand_vision:)
    @brand_concept = brand_concept
    @brand_vision = brand_vision
    @openai_client = nil
  end

  # Generate vision statement candidates
  # @return [Array<String>] Array of 3 vision statement candidates
  def generate
    return [] if openai_client.nil?
    return [] if @brand_concept.blank? && @brand_vision.mission_statement.blank?

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
      Rails.logger.error("VisionStatementGeneratorService: OpenAI API error: #{e.message}")
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
      Rails.logger.warn("VisionStatementGeneratorService: OPENAI_API_KEY not set, generation disabled")
      @openai_client = nil
    end

    @openai_client
  end

  def system_prompt
    <<~PROMPT
      You are a professional brand strategist helping to develop vision statements for brands.
      A vision statement defines the aspirational future a brand is working towards - where they want to be, and what impact they want to have.

      Based on the brand information provided, generate exactly 3 different vision statement candidates that:
      1. Are inspiring and aspirational (1-2 sentences maximum)
      2. Paint a picture of the future the brand is working to create
      3. Are forward-looking and ambitious but achievable
      4. Align with the brand's mission, category, and personality
      5. Are authentic and specific (not generic corporate-speak)
      6. Vary in style and approach to give the user meaningful choices

      The three candidates should offer different perspectives:
      - One focused on the customer/community impact
      - One focused on the industry or market transformation
      - One focused on the broader societal or global change

      IMPORTANT: You must respond with valid JSON only. Use this exact structure:
      {
        "vision_statements": [
          "First vision statement candidate here.",
          "Second vision statement candidate here.",
          "Third vision statement candidate here."
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

    if @brand_vision.traits.present? && @brand_vision.traits.any?
      vision_parts << "Brand traits: #{@brand_vision.traits.join(', ')}"
    end

    if @brand_vision.tone.present? && @brand_vision.tone.any?
      vision_parts << "Brand tone: #{@brand_vision.tone.join(', ')}"
    end

    if vision_parts.any?
      parts << "Brand Information:"
      parts << vision_parts.join("\n")
      parts << ""
    end

    parts << "Based on the above, generate exactly 3 different vision statement candidates."
    parts.join("\n")
  end

  def parse_response(content)
    return [] if content.blank?

    data = JSON.parse(content)
    statements = data["vision_statements"] || []

    # Return only valid non-empty strings, limit to 3
    statements.select { |s| s.is_a?(String) && s.present? }.take(3)
  rescue JSON::ParserError => e
    Rails.logger.error("VisionStatementGeneratorService: Failed to parse JSON response: #{e.message}")
    []
  end
end
