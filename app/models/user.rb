class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :brand_memberships, dependent: :destroy
  has_many :brands, through: :brand_memberships

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  def password_reset_token
    signed_id(purpose: :password_reset, expires_in: password_reset_token_expires_in)
  end

  def password_reset_token_expires_in
    1.hour
  end

  def self.find_by_password_reset_token!(token)
    find_signed!(token, purpose: :password_reset)
  end
end
