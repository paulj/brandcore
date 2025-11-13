class Brand < ApplicationRecord
  has_paper_trail

  # Relationships
  has_many :brand_memberships, dependent: :destroy
  has_many :users, through: :brand_memberships

  has_one :brand_concept, dependent: :destroy
  has_one :brand_name, dependent: :destroy
  has_many :properties, class_name: "BrandProperty", dependent: :destroy
  has_one :brand_logo, dependent: :destroy
  has_one :brand_language, dependent: :destroy
  has_one :brand_colour_scheme, dependent: :destroy
  has_one :brand_typography, dependent: :destroy
  has_one :brand_ui, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :status, inclusion: { in: %w[draft published archived] }

  # Callbacks
  before_validation :generate_working_name, if: -> { name.blank? }
  before_validation :generate_slug, if: -> { name.present? && (slug.blank? || name_changed?) }

  # Use slug in URLs
  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end

  def generate_working_name
    adjective = BRAND_ADJECTIVES.sample
    noun = BRAND_NOUNS.sample
    self.name = "#{adjective} #{noun}"
    self.is_working_name = true
  end
end
