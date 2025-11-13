# frozen_string_literal: true

# Background job to generate colour palette candidates using BrandColorPalette::Generator
class GeneratePalettesJob < ApplicationJob
  queue_as :default

  def perform(brand)
    generator = BrandColorPalette::Generator.new(brand)
    result = generator.generate

    # Convert result to JSON-friendly format for the view
    palettes_data = result.palettes.map do |palette|
      {
        scheme: palette.scheme,
        score: palette.score,
        accessible: palette.accessible?,
        colors: palette.colors.map do |color|
          {
            role: color.role,
            name: color.role.to_s.titleize,
            hex: color.hex,
            oklch: color.oklch.to_h,
            rgb: color.rgb.to_h
          }
        end,
        metadata: {
          # description: palette.metadata&.description,
          # vibe: palette.metadata&.vibe
        },
        accessibility: palette.accessibility&.to_h
      }
    end

    # Broadcast the results via Action Cable
    broadcast_palettes(brand, palettes_data)
  rescue StandardError => e
    Rails.logger.error("GeneratePalettesJob failed for brand #{brand.id}: #{e.message}\n#{e.backtrace.join("\n")}")
    broadcast_error(brand, e.message)
  end

  private

  def broadcast_palettes(brand, palettes)
    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_colour_scheme_#{brand.id}",
      target: "palette_suggestions",
      partial: "brand/colour_scheme/palette_suggestions",
      locals: { palettes: palettes, brand: brand }
    )
  end

  def broadcast_error(brand, error_message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "brand_colour_scheme_#{brand.id}",
      target: "palette_suggestions",
      partial: "brand/colour_scheme/palette_error",
      locals: { error_message: error_message }
    )
  end
end
