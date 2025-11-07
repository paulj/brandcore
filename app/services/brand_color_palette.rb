# frozen_string_literal: true

# Brand Color Palette Generator Module
#
# A comprehensive system for generating brand color palettes based on brand vision details.
# The module processes brand traits, tone, audiences, category, and markets through a
# multi-step pipeline to produce accessible, culturally-appropriate color palettes.
#
# Pipeline:
# 1. NLP Normalization - Extract and map brand inputs to design axes
# 2. Emotion-Color Mapping - Map traits to color families and hues
# 3. Palette Generation - Create palettes using OKLCH color space and harmony schemes
# 4. Constraint Layer - Apply accessibility (WCAG), cultural, and category constraints
# 5. Output Generation - Produce light/dark mode variations in multiple formats
#
# @example Basic usage
#   input = {
#     brand_id: "acme",
#     traits: ["innovative", "approachable", "premium"],
#     tone: ["confident", "friendly"],
#     audiences: ["prosumer", "SMB"],
#     category: "SaaS",
#     markets: ["US", "AU"],
#     keywords: ["automation", "reliability", "speed"]
#   }
#
#   generator = BrandColorPalette::Generator.new(input)
#   result = generator.generate
#
#   # Get just the best palette
#   best = generator.generate_best
#
module BrandColorPalette
  # Load all submodules
  autoload :ColorSpace, "brand_color_palette/color_space"
  autoload :EmotionColorMap, "brand_color_palette/emotion_color_map"
  autoload :NlpNormalizer, "brand_color_palette/nlp_normalizer"
  autoload :WcagChecker, "brand_color_palette/wcag_checker"
  autoload :PaletteGenerator, "brand_color_palette/palette_generator"
  autoload :ConstraintLayer, "brand_color_palette/constraint_layer"
  autoload :Generator, "brand_color_palette/generator"
end
