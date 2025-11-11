class BrandMembership < ApplicationRecord
  belongs_to :brand
  belongs_to :user
  belongs_to :invited_by, class_name: "User", optional: true, foreign_key: :invited_by_user_id

  validates :brand_id, uniqueness: { scope: :user_id }
  validates :role, inclusion: { in: %w[owner editor viewer] }

  validate :at_least_one_owner

  private

  def at_least_one_owner
    if role_changed? && role_was == "owner"
      remaining_owners = brand.brand_memberships.where(role: "owner").where.not(id: id).count
      if remaining_owners.zero?
        errors.add(:role, "cannot be changed - brand must have at least one owner")
      end
    end
  end
end
