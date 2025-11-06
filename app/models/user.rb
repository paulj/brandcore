class User < ApplicationRecord
  has_secure_password

  # Relationships
  has_many :brand_memberships, dependent: :destroy
  has_many :brands, through: :brand_memberships

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
end
