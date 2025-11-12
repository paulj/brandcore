# frozen_string_literal: true

# Service to generate target audience suggestions using OpenAI
class TargetAudienceGeneratorService
  def initialize(brand_concept:, brand_vision:)
    @brand_concept = brand_concept
    @brand_vision = brand_vision
    @openai_client = nil
  end

  # Generate target audience suggestions
  # @return [Array<String>] Array of audience segments
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
          temperature: 0.7,
          response_format: { type: "json_object" }
        }
      )

      content = response.dig("choices", 0, "message", "content")
      parse_response(content)
    rescue StandardError => e
      Rails.logger.error("TargetAudienceGeneratorService: OpenAI API error: #{e.message}")
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
      Rails.logger.warn("TargetAudienceGeneratorService: OPENAI_API_KEY not set, generation disabled")
      @openai_client = nil
    end

    @openai_client
  end

  def system_prompt
    <<~PROMPT
      You are a professional brand strategist helping to identify target audiences for brands.
      Target audiences are specific segments of people that a brand serves or aims to reach.

      Based on the brand information provided, generate 5-7 specific target audience segments that:
      1. Are clearly defined and specific (not "everyone")
      2. Align with the brand's mission, vision, and category
      3. Are realistic and achievable for the brand to reach
      4. Use clear, descriptive language (e.g., "small business owners", "health-conscious millennials", "enterprise IT decision-makers")
      5. Vary in specificity and approach to give comprehensive coverage

      IMPORTANT: You must respond with valid JSON only. Use this exact structure:
      {
        "audiences": [
          "audience segment 1",
          "audience segment 2",
          "audience segment 3",
          "audience segment 4",
          "audience segment 5"
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

    if @brand_vision.traits.present? && @brand_vision.traits.any?
      vision_parts << "Brand traits: #{@brand_vision.traits.join(', ')}"
    end

    if vision_parts.any?
      parts << "Brand Information:"
      parts << vision_parts.join("\n")
      parts << ""
    end

    parts << "Based on the above, generate specific target audience segments for this brand."
    parts.join("\n")
  end

  def parse_response(content)
    return [] if content.blank?

    data = JSON.parse(content)
    audiences = data["audiences"] || []

    # Return only valid non-empty strings
    audiences.select { |a| a.is_a?(String) && a.present? }
  rescue JSON::ParserError => e
    Rails.logger.error("TargetAudienceGeneratorService: Failed to parse JSON response: #{e.message}")
    []
  end
end
