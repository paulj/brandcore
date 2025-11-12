# frozen_string_literal: true

module BrandColorPalette
  # CMYK color representation
  CmykColor = Struct.new(:c, :m, :y, :k, keyword_init: true) do
    def to_h
      { c: c, m: m, y: y, k: k }
    end
  end
end
