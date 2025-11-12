# frozen_string_literal: true

module BrandColorPalette
  # Trait mapping information
  TraitMapping = Struct.new(:original, :mapped, keyword_init: true) do
    def to_h
      { original: original, mapped: mapped }
    end
  end
end
