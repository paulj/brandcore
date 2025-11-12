# frozen_string_literal: true

# Service to generate core values using OpenAI based on mission and vision statements
class CoreValuesGeneratorService
  ICON_OPTIONS = [
    "fa-solid fa-heart",
    "fa-solid fa-star",
    "fa-solid fa-shield",
    "fa-solid fa-lightbulb",
    "fa-solid fa-rocket",
    "fa-solid fa-users",
    "fa-solid fa-handshake",
    "fa-solid fa-trophy",
    "fa-solid fa-compass",
    "fa-solid fa-gem",
    "fa-solid fa-bolt",
    "fa-solid fa-fire",
    "fa-solid fa-leaf",
    "fa-solid fa-crown",
    "fa-solid fa-thumbs-up",
    "fa-solid fa-balance-scale",
    "fa-solid fa-brain",
    "fa-solid fa-eye"
  ].freeze

  def initialize(mission_statement:, vision_statement:)
    @mission_statement = mission_statement
    @vision_statement = vision_statement
    @openai_client = nil
  end

  # Generate core values based on mission and vision
  # @return [Array<CoreValue>] Array of generated core values (3-5 values)
  def generate
    return [] if openai_client.nil?
    return [] if @mission_statement.blank? && @vision_statement.blank?

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
      Rails.logger.error("CoreValuesGeneratorService: OpenAI API error: #{e.message}")
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
      Rails.logger.warn("CoreValuesGeneratorService: OPENAI_API_KEY not set, generation disabled")
      @openai_client = nil
    end

    @openai_client
  end

  def system_prompt
    <<~PROMPT
      You are a professional brand strategist helping to develop core values for a brand.
      Core values are the fundamental beliefs that guide a brand's decisions, culture, and behaviour.

      Based on the mission and vision statements provided, generate 3-5 core values that:
      1. Align with the brand's stated purpose and aspirations
      2. Are authentic and specific (not generic corporate-speak)
      3. Can guide real decision-making
      4. Reflect what makes this brand unique

      For each core value, provide:
      - name: A concise 1-3 word title (e.g., "Customer Obsession", "Innovation", "Integrity")
      - description: 1-2 sentences explaining what this value means in practice for this specific brand
      - icon: Choose the most appropriate icon from this list based on the value's meaning:
        #{ICON_OPTIONS.join(", ")}

      IMPORTANT: You must respond with valid JSON only. Use this exact structure:
      {
        "core_values": [
          {
            "name": "Value Name",
            "description": "Brief description of what this value means.",
            "icon": "fa-solid fa-icon-name"
          }
        ]
      }
    PROMPT
  end

  def user_prompt
    parts = []

    if @mission_statement.present?
      parts << "Mission Statement: #{@mission_statement}"
    end

    if @vision_statement.present?
      parts << "Vision Statement: #{@vision_statement}"
    end

    parts << "\nBased on the above, generate 3-5 core values for this brand."
    parts.join("\n\n")
  end

  def parse_response(content)
    return [] if content.blank?

    data = JSON.parse(content)
    values_data = data["core_values"] || []

    values_data.map do |value_hash|
      CoreValue.new(
        name: value_hash["name"],
        description: value_hash["description"],
        icon: validate_icon(value_hash["icon"])
      )
    end.select(&:valid?)
  rescue JSON::ParserError => e
    Rails.logger.error("CoreValuesGeneratorService: Failed to parse JSON response: #{e.message}")
    []
  end

  def validate_icon(icon)
    ICON_OPTIONS.include?(icon) ? icon : "fa-solid fa-heart"
  end
end
