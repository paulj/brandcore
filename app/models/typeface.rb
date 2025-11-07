# frozen_string_literal: true

class Typeface < ApplicationRecord
  # Available roles for typefaces
  ROLES = %w[primary secondary heading body].freeze

  belongs_to :brand_typography

  # Structured JSONB attributes
  attribute :type_scale, TypeScaleItem.to_array_type

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :name, presence: true
  validates :family, presence: true
  validates :category, presence: true
  validates :brand_typography_id, uniqueness: { scope: :role, message: "already has a typeface with this role" }
  validate :role_allowed_by_scheme

  scope :by_role, ->(role) { where(role: role) }
  scope :ordered, -> { order(:position, :created_at) }

  # Type scale helpers (backwards compatibility)
  def type_scale_value(key)
    return nil if type_scale.blank?
    item = type_scale.find { |item| item.font_size == key.to_s }
    item&.font_size
  end

  def line_height_value(key)
    return nil if type_scale.blank?
    item = type_scale.find { |item| item.font_size == key.to_s }
    item&.line_height
  end

  private

  def role_allowed_by_scheme
    return if brand_typography.blank? || brand_typography.scheme.blank?

    allowed_roles = brand_typography.required_roles
    unless allowed_roles.include?(role)
      errors.add(:role, "is not allowed for the '#{brand_typography.scheme}' scheme. Allowed roles: #{allowed_roles.join(', ')}")
    end
  end
end
