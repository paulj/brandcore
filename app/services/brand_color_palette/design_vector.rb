module BrandColorPalette
  DesignVector = Struct.new(
    :warmth,
    :boldness,
    :playfulness,
    :modernity,
    :contrast,
    :saturation,
    keyword_init: true
  ) do
    def self.from_hash(hash)
      new(
        warmth: hash[:warmth] || 0.0,
        boldness: hash[:boldness] || 0.0,
        playfulness: hash[:playfulness] || 0.0,
        modernity: hash[:modernity] || 0.0,
        contrast: hash[:contrast] || 0.0,
        saturation: hash[:saturation] || 0.0
      )
    end

    def to_h
      {
        warmth: warmth,
        boldness: boldness,
        playfulness: playfulness,
        modernity: modernity,
        contrast: contrast,
        saturation: saturation
      }
    end
  end
end
