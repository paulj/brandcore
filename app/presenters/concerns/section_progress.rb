# frozen_string_literal: true

# SectionProgress defines the standard interface for section progress presenters.
# Each brand component section presenter should include this module and implement
# the required methods to calculate completion metrics.
#
# Required methods to implement:
# - #total_fields: Integer - Total number of completable fields in the section
# - #completed_fields: Integer - Number of fields that have been completed
#
# Provided methods:
# - #completion_count: String - Formatted "X of Y completed"
# - #completion_percentage: Integer - Percentage complete (0-100)
# - #completed?: Boolean - Whether the section is 100% complete
module SectionProgress
  # Returns a formatted string showing completion count
  # @return [String] e.g., "3 of 5 completed"
  def completion_count
    "#{completed_fields} of #{total_fields} completed"
  end

  # Returns the completion percentage
  # @return [Integer] 0-100
  def completion_percentage
    return 0 if total_fields.zero?

    ((completed_fields.to_f / total_fields) * 100).round
  end

  # Returns whether the section is fully complete
  # @return [Boolean]
  def completed?
    completed_fields == total_fields && total_fields.positive?
  end

  private

  # Subclasses must implement this method
  # @return [Integer]
  def total_fields
    raise NotImplementedError, "#{self.class} must implement #total_fields"
  end

  # Subclasses must implement this method
  # @return [Integer]
  def completed_fields
    raise NotImplementedError, "#{self.class} must implement #completed_fields"
  end
end
