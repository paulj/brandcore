# frozen_string_literal: true

module BrandColorPalette
  # OKLCH color representation
  OklchColor = Struct.new(:l, :c, :h, keyword_init: true) do
    def to_h
      { l: l, c: c, h: h }
    end
  end
end
