# frozen_string_literal: true

# Service to generate keywords suggestions using OpenAI
class KeywordsGeneratorService
  def initialize(brand_concept:, brand_vision:)
    @brand_concept = brand_concept
    @brand_vision = brand_vision
    @openai_client = nil
  end

  # Generate keywords suggestions
  # @return [Array<String>] Array of brand keywords
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
          temperature: 0.7,
          response_format: { type: "json_object" }
        }
      )

      content = response.dig("choices", 0, "message", "content")
      parse_response(content)
    rescue StandardError => e
      Rails.logger.error("KeywordsGeneratorService: OpenAI API error: #{e.message}")
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
      Rails.logger.warn("KeywordsGeneratorService: OPENAI_API_KEY not set, generation disabled")
      @openai_client = nil
    end

    @openai_client
  end

  def system_prompt
    <<~PROMPT
      You are a professional brand strategist helping to define brand keywords.
      Brand keywords are key terms and concepts that capture the essence of what the brand is about.

      Based on the brand information provided, generate 8-12 keywords that:
      1. Capture the brand's core themes and values
      2. Are concise (1-2 words each) - prefer single words even over two word keywords, even if they are more general.
      3. Are specific and memorable (not generic terms like "quality" or "excellence")
      4. Cover different aspects: what the brand does, how it does it, who it serves, and what it stands for
      5. Can be used for brand messaging, SEO, and content strategy

      IMPORTANT: You must respond with valid JSON only. Use this exact structure:
      {
        "keywords": [
          "keyword1",
          "keyword2",
          "keyword3",
          "keyword4",
          "keyword5",
          "keyword6",
          "keyword7",
          "keyword8"
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

    if @brand_vision.traits.present? && @brand_vision.traits.any?
      vision_parts << "Brand traits: #{@brand_vision.traits.join(', ')}"
    end

    if vision_parts.any?
      parts << "Brand Information:"
      parts << vision_parts.join("\n")
      parts << ""
    end

    parts << "Based on the above, generate brand keywords that capture the essence of this brand."
    parts.join("\n")
  end

  def parse_response(content)
    return [] if content.blank?

    data = JSON.parse(content)
    keywords = data["keywords"] || []

    # Return only valid non-empty strings
    keywords.select { |k| k.is_a?(String) && k.present? }
  rescue JSON::ParserError => e
    Rails.logger.error("KeywordsGeneratorService: Failed to parse JSON response: #{e.message}")
    []
  end
end
