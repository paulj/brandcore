# frozen_string_literal: true

# GoogleFontsService fetches and caches Google Fonts metadata.
# Uses the Google Fonts Developer API or falls back to a static data source.
class GoogleFontsService
  API_URL = "https://www.googleapis.com/webfonts/v1/webfonts"
  CACHE_KEY = "google_fonts_list"
  CACHE_EXPIRY = 24.hours

  class << self
    # Fetch all fonts from Google Fonts API
    # @return [Array<Hash>] Array of font metadata hashes
    def fetch_fonts
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_EXPIRY) do
        fetch_from_api || fetch_from_static_source
      end
    end

    # Search fonts by name
    # @param query [String] Search query
    # @return [Array<Hash>] Filtered fonts
    def search_fonts(query)
      return [] if query.blank?

      fonts = fetch_fonts
      query_downcase = query.downcase

      fonts.select do |font|
        font["family"]&.downcase&.include?(query_downcase) ||
          font["category"]&.downcase&.include?(query_downcase)
      end
    end

    # Get fonts by category
    # @param category [String] Font category (serif, sans-serif, display, handwriting, monospace)
    # @return [Array<Hash>] Fonts in the category
    def fonts_by_category(category)
      return [] if category.blank?

      fetch_fonts.select { |font| font["category"]&.downcase == category.downcase }
    end

    # Get a single font by family name
    # @param family_name [String] Font family name
    # @return [Hash, nil] Font metadata or nil
    def font_by_family(family_name)
      return nil if family_name.blank?

      fetch_fonts.find { |font| font["family"] == family_name }
    end

    # Generate Google Fonts CSS import URL for selected fonts
    # @param font_families [Array<String>] Array of font family names
    # @return [String] CSS import URL
    def css_import_url(font_families)
      return "" if font_families.blank?

      families = font_families.map { |f| f.gsub(" ", "+") }
      weights = "300;400;500;600;700" # Common weights
      "https://fonts.googleapis.com/css2?#{families.map { |f| "family=#{f}:#wght@#{weights}" }.join("&")}&display=swap"
    end

    def build_static_source
      File.write("config/google_fonts.json", JSON.pretty_generate({ items: fetch_from_api }))
    end

    private

    def fetch_from_api
      api_key = Rails.application.config.google_fonts_api_key
      return nil unless api_key.present?

      connection = Faraday.new(url: API_URL) do |conn|
        conn.adapter Faraday.default_adapter
      end

      response = connection.get do |req|
        req.params["key"] = api_key
        req.params["sort"] = "popularity"
      end

      if response.success?
        data = JSON.parse(response.body)
        data["items"] || []
      else
        Rails.logger.warn("Google Fonts API request failed: #{response.status} #{response.reason_phrase}")
        nil
      end
    rescue StandardError => e
      Rails.logger.error("Error fetching Google Fonts API: #{e.message}")
      nil
    end

    def fetch_from_static_source
      # Fallback: Try to load from a local JSON file if API fails
      # This would need to be populated with a one-time download
      file_path = Rails.root.join("config", "google_fonts.json")
      if File.exist?(file_path)
        JSON.parse(File.read(file_path))["items"] || []
      else
        # Return empty array and log warning
        Rails.logger.warn("Google Fonts static data not found. Please configure API key or add static data file.")
        []
      end
    rescue StandardError => e
      Rails.logger.error("Error loading static Google Fonts data: #{e.message}")
      []
    end
  end
end
