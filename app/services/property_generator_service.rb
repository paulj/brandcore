# frozen_string_literal: true

# Unified service to generate property suggestions using OpenAI.
# Uses PropertyConfiguration to get prompts and generate suggestions for any property.
#
# Example usage:
#   service = PropertyGeneratorService.new(
#     brand: brand,
#     property_name: "mission"
#   )
#   suggestions = service.generate
#   # => [#<BrandProperty>, #<BrandProperty>, #<BrandProperty>]
class PropertyGeneratorService
  def initialize(brand:, property_name:)
    @brand = brand
    @property_name = property_name.to_s
    @configuration = PropertyConfiguration.for(@property_name)
    @openai_client = nil
  end

  # Generate property suggestions
  # @return [Array<BrandProperty>] Array of unsaved BrandProperty objects with status: :suggestion
  def generate
    return [] if openai_client.nil?
    return [] unless dependencies_met?

    begin
      response = openai_client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            {
              role: "user",
              content: rendered_prompt
            }
          ],
          temperature: @configuration.temperature,
          response_format: { type: "json_object" }
        }
      )

      content = response.dig("choices", 0, "message", "content")
      parse_response(content)
    rescue StandardError => e
      Rails.logger.error("PropertyGeneratorService: OpenAI API error for #{@property_name}: #{e.message}")
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
      Rails.logger.warn("PropertyGeneratorService: OPENAI_API_KEY not set, generation disabled")
      @openai_client = nil
    end

    @openai_client
  end

  def dependencies_met?
    unless @configuration.dependencies_met?(@brand)
      missing = @configuration.dependencies.reject do |dep|
        @brand.properties.for_property(dep).current.exists?
      end
      Rails.logger.warn(
        "PropertyGeneratorService: Missing dependencies for #{@property_name}: #{missing.join(', ')}"
      )
      return false
    end

    true
  end

  def rendered_prompt
    context = build_context
    @configuration.prompt(context)
  end

  def build_context
    context = {}

    # Add brand concept if available
    context[:brand_concept] = @brand.brand_concept&.concept

    # Add all current property values as potential dependencies
    # For single-cardinality: get the first value
    # For multiple-cardinality: get all values as an array
    @brand.properties.current.group_by(&:property_name).each do |prop_name, properties|
      config = PropertyConfiguration.for(prop_name)

      if config.single?
        # Single property - just get the value
        context[prop_name.to_sym] = properties.first&.text_value
      else
        # Multiple properties - get all values as an array
        context[prop_name.to_sym] = properties.map(&:text_value)
      end
    end

    context
  end

  def parse_response(content)
    return [] if content.blank?

    data = JSON.parse(content)
    suggestions_data = data[@configuration.json_key]

    # Handle both single values and arrays
    suggestions_array = Array.wrap(suggestions_data)

    # Create BrandProperty objects for each suggestion
    # Each suggestion becomes its own property record
    suggestions_array.map do |suggestion_value|
      next if suggestion_value.blank?

      @brand.properties.build(
        property_name: @property_name,
        value: normalize_value(suggestion_value),
        status: :suggestion,
        generated_at: Time.current
      )
    end.compact
  rescue JSON::ParserError => e
    Rails.logger.error("PropertyGeneratorService: Failed to parse JSON response for #{@property_name}: #{e.message}")
    []
  end

  def normalize_value(value)
    case value
    when String, Numeric, TrueClass, FalseClass
      value
    when Hash
      value
    else
      value.to_s
    end
  end
end
