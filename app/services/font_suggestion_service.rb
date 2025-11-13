# frozen_string_literal: true

# FontSuggestionService suggests fonts based on brand properties.
# Maps brand attributes to appropriate font categories and specific font recommendations.
class FontSuggestionService
  # Font category mappings based on brand personality traits
  PERSONALITY_TO_CATEGORY = {
    "traditional" => "serif",
    "classic" => "serif",
    "elegant" => "serif",
    "professional" => "sans-serif",
    "modern" => "sans-serif",
    "minimalist" => "sans-serif",
    "clean" => "sans-serif",
    "playful" => "display",
    "creative" => "display",
    "bold" => "display",
    "friendly" => "sans-serif",
    "approachable" => "sans-serif",
    "handcrafted" => "handwriting",
    "artisan" => "handwriting",
    "technical" => "monospace",
    "code" => "monospace"
  }.freeze

  # Popular, well-designed fonts by category
  RECOMMENDED_FONTS = {
    "serif" => [
      "Playfair Display",
      "Merriweather",
      "Lora",
      "Crimson Text",
      "Libre Baskerville",
      "PT Serif"
    ],
    "sans-serif" => [
      "Inter",
      "Roboto",
      "Open Sans",
      "Lato",
      "Montserrat",
      "Poppins",
      "Source Sans Pro",
      "Work Sans"
    ],
    "display" => [
      "Bebas Neue",
      "Oswald",
      "Raleway",
      "Bungee",
      "Righteous",
      "Fredoka One"
    ],
    "handwriting" => [
      "Dancing Script",
      "Pacifico",
      "Caveat",
      "Kalam",
      "Shadows Into Light"
    ],
    "monospace" => [
      "Roboto Mono",
      "Source Code Pro",
      "Fira Code",
      "Courier Prime",
      "IBM Plex Mono"
    ]
  }.freeze

  def initialize(brand)
    @brand = brand
  end

  # Suggest fonts based on brand properties
  # @return [Array<Hash>] Array of suggested font metadata
  def suggest_fonts(limit: 6)
    category = determine_category
    fonts = GoogleFontsService.fonts_by_category(category)

    # If we have specific recommendations for this category, prioritize them
    recommended = RECOMMENDED_FONTS[category] || []
    suggested = []

    # First, try to include recommended fonts
    recommended.each do |font_name|
      font = fonts.find { |f| f["family"] == font_name }
      suggested << font if font
      break if suggested.size >= limit
    end

    # Fill remaining slots with other fonts from the category
    fonts.each do |font|
      next if suggested.any? { |s| s["family"] == font["family"] }
      suggested << font
      break if suggested.size >= limit
    end

    suggested
  end

  # Determine the most appropriate font category based on brand properties
  # @return [String] Font category name
  def determine_category
    # Check brand traits
    traits = @brand.properties.for_property("trait").current.map(&:text_value)
    if traits.any?
      category = find_category_for_traits(traits)
      return category if category
    end

    # Check brand tone
    tone = @brand.properties.for_property("tone").current.map(&:text_value)
    if tone.any?
      category = find_category_for_traits(tone)
      return category if category
    end

    # Check mission/vision statements
    mission = @brand.properties.for_property("mission").current.first&.text_value
    vision = @brand.properties.for_property("vision").current.first&.text_value
    combined_text = [ mission, vision ].compact.join(" ")

    return analyze_text_for_category(combined_text) if combined_text.present?

    # Default to sans-serif (most versatile)
    "sans-serif"
  end

  private

  def find_category_for_traits(traits)
    traits.each do |trait|
      trait_lower = trait.downcase
      PERSONALITY_TO_CATEGORY.each do |keyword, category|
        return category if trait_lower.include?(keyword)
      end
    end
    nil
  end

  def analyze_text_for_category(text)
    text_lower = text.downcase

    # Check for keywords that suggest specific categories
    if text_lower.match?(/\b(traditional|classic|elegant|heritage|established)\b/)
      return "serif"
    end

    if text_lower.match?(/\b(modern|minimalist|clean|sleek|contemporary|tech|digital)\b/)
      return "sans-serif"
    end

    if text_lower.match?(/\b(playful|creative|bold|energetic|fun|vibrant)\b/)
      return "display"
    end

    if text_lower.match?(/\b(handcrafted|artisan|personal|authentic|organic)\b/)
      return "handwriting"
    end

    if text_lower.match?(/\b(technical|code|developer|programming)\b/)
      return "monospace"
    end

    nil
  end
end
