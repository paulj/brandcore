# frozen_string_literal: true

module BrandColorPalette
  # RGB color representation
  RgbColor = Struct.new(:r, :g, :b, keyword_init: true) do
    def to_h
      { r: r, g: g, b: b }
    end
  end
end
