class CoreValue
  include StoreModel::Model

  attribute :name, :string
  attribute :description, :string
  attribute :icon, :string, default: "fa-solid fa-heart"

  validates :name, presence: true
end
