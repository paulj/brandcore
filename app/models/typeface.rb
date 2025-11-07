# frozen_string_literal: true

class Typeface
  include StoreModel::Model

  attribute :name, :string
  attribute :family, :string
  attribute :category, :string
  attribute :variants, :string_array, default: []
  attribute :subsets, :string_array, default: []
  attribute :google_fonts_url, :string

  validates :name, presence: true
  validates :family, presence: true
  validates :category, presence: true
end
