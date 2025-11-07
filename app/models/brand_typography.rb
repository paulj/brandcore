class BrandTypography < ApplicationRecord
  # has_paper_trail

  # Typography schemes define which typeface roles are available
  SCHEMES = {
    "single" => {
      name: "Single",
      description: "One typeface for all uses",
      roles: %w[primary]
    },
    "primary_secondary" => {
      name: "Primary/Secondary",
      description: "Primary and secondary typefaces",
      roles: %w[primary secondary]
    },
    "heading_body" => {
      name: "Heading/Body",
      description: "Separate typefaces for headings and body text",
      roles: %w[heading body]
    }
  }.freeze

  belongs_to :brand
  has_many :typefaces, dependent: :destroy

  accepts_nested_attributes_for :typefaces, allow_destroy: true

  validates :brand_id, uniqueness: true
  validates :scheme, inclusion: { in: SCHEMES.keys }, allow_nil: true

  # Get the roles required for the current scheme
  def required_roles
    return [] if scheme.blank?
    SCHEMES[scheme]&.dig(:roles) || []
  end

  # Check if all required typefaces for the scheme are set
  def scheme_complete?
    return false if scheme.blank?
    required_roles.all? { |role| typeface_by_role(role).present? && typeface_by_role(role).name.present? }
  end

  # Helper methods for backward compatibility and convenience
  def primary_typeface
    typefaces.find_by(role: "primary")
  end

  def secondary_typeface
    typefaces.find_by(role: "secondary")
  end

  def heading_typeface
    typefaces.find_by(role: "heading")
  end

  def body_typeface
    typefaces.find_by(role: "body")
  end

  def typeface_by_role(role)
    typefaces.find_by(role: role)
  end
end
