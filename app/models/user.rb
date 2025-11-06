class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :brand_memberships, dependent: :destroy
  has_many :brands, through: :brand_memberships

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
end
