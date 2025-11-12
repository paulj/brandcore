# frozen_string_literal: true

# Suggestion model for persisting AI-generated suggestions
# Polymorphic association allows suggestions for any brand component
class Suggestion < ApplicationRecord
  belongs_to :suggestionable, polymorphic: true

  enum status: { pending: 0, chosen: 1, archived: 2 }

  validates :field_name, presence: true
  validates :content, presence: true
  validates :status, presence: true

  scope :for_field, ->(field_name) { where(field_name: field_name) }
  scope :recent_first, -> { order(created_at: :desc) }

  # Archive all other pending suggestions for the same field
  def archive_siblings
    self.class
      .where(suggestionable: suggestionable, field_name: field_name)
      .where.not(id: id)
      .pending
      .update_all(status: :archived, archived_at: Time.current)
  end

  # Mark this suggestion as chosen and archive siblings
  def choose!
    transaction do
      update!(status: :chosen, chosen_at: Time.current)
      archive_siblings
    end
  end

  # Mark this suggestion as archived
  def archive!
    update!(status: :archived, archived_at: Time.current)
  end

  # Helper to get text content for simple suggestions
  def text_content
    content.is_a?(Hash) ? content["text"] : content.to_s
  end
end
