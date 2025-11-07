class TypeScaleItem
  include StoreModel::Model

  attribute :font_size, :string
  attribute :line_height, :string
  attribute :variant, :string, default: "Regular"
  attribute :font_weight, :string, default: "400"

  validates :font_size, presence: true
  validates :line_height, presence: true
  validates :variant, presence: true
  validates :font_weight, presence: true
end

