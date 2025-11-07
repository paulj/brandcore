# frozen_string_literal: true

namespace :brand_color_palette do
  desc "Generate embeddings cache for known traits"
  task generate_trait_embeddings: :environment do
    require "openai"
    require_relative "../../app/services/brand_color_palette/emotion_color_map"

    api_key = ENV["OPENAI_API_KEY"]
    unless api_key.present?
      puts "❌ Error: OPENAI_API_KEY environment variable not set"
      puts "   Set it with: export OPENAI_API_KEY='your-api-key'"
      exit 1
    end

    client = OpenAI::Client.new(access_token: api_key)
    known_traits = BrandColorPalette::EmotionColorMap::TRAIT_COLOR_MAP.keys
    cache_file = Rails.root.join("lib/data/trait_embeddings.json")

    puts "🎨 Generating embeddings for #{known_traits.length} known traits..."
    puts "   Model: text-embedding-3-small"
    puts "   Output: #{cache_file}"
    puts ""

    embeddings_cache = {}
    failed_traits = []

    known_traits.each_with_index do |trait, index|
      print "   [#{index + 1}/#{known_traits.length}] #{trait.ljust(20)}"

      begin
        response = client.embeddings(
          parameters: {
            model: "text-embedding-3-small",
            input: trait
          }
        )

        embedding = response.dig("data", 0, "embedding")
        if embedding
          embeddings_cache[trait] = embedding
          puts "✓ (#{embedding.length} dimensions)"
        else
          puts "✗ (no embedding returned)"
          failed_traits << trait
        end
      rescue StandardError => e
        puts "✗ (error: #{e.message})"
        failed_traits << trait
      end

      # Small delay to respect rate limits
      sleep 0.1
    end

    puts ""

    if failed_traits.any?
      puts "⚠️  Warning: Failed to generate embeddings for #{failed_traits.length} traits:"
      failed_traits.each { |trait| puts "   - #{trait}" }
      puts ""
    end

    # Save to JSON file
    File.write(cache_file, JSON.pretty_generate(embeddings_cache))

    puts "✅ Successfully cached #{embeddings_cache.length} trait embeddings"
    puts "   File size: #{File.size(cache_file) / 1024} KB"
    puts "   Ready to use for trait mapping!"
    puts ""
    puts "💡 Tip: Commit #{cache_file} to your repository"
    puts "   This allows the app to work without needing OPENAI_API_KEY for known traits"
  end

  desc "Test trait mapping with arbitrary input"
  task :test_trait_mapping, [ :trait ] => :environment do |_t, args|
    trait = args[:trait]

    unless trait.present?
      puts "Usage: rake brand_color_palette:test_trait_mapping['your_trait']"
      puts "Example: rake brand_color_palette:test_trait_mapping['inventive']"
      exit 1
    end

    require_relative "../../app/services/brand_color_palette/emotion_color_map"
    require_relative "../../app/services/brand_color_palette/trait_mapper"

    mapper = BrandColorPalette::TraitMapper.new

    puts "🔍 Testing trait mapping for: '#{trait}'"
    puts ""

    mapped = mapper.map_trait(trait)

    if mapped
      color_data = BrandColorPalette::EmotionColorMap.color_for_trait(mapped)
      puts "✅ Mapped to: '#{mapped}'"
      puts ""
      puts "   Color families: #{color_data[:families].join(', ')}"
      puts "   Hues: #{color_data[:hues].join(', ')}°"
      puts "   Warmth: #{color_data[:warmth]}"
      puts "   Saturation: #{color_data[:saturation]}"
    else
      puts "❌ No suitable match found (below similarity threshold)"
      puts ""
      puts "   Consider adding '#{trait}' to EmotionColorMap if it's a common trait"
    end
  end
end
