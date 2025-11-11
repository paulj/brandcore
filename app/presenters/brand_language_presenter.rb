# frozen_string_literal: true

# BrandLanguagePresenter calculates completion status for the Brand Language section.
# It tracks completion based on:
# - Tone of voice defined
# - Tagline provided
# - Vocabulary guidelines defined
# - Writing style notes provided
class BrandLanguagePresenter
  include SectionProgress

  def initialize(brand_language)
    @brand_language = brand_language
  end

  # Total number of completable fields in the Language section
  # @return [Integer]
  def total_fields
    4
  end

  # Number of completed fields in the Language section
  # @return [Integer]
  def completed_fields
    count = 0
    count += 1 if tone_of_voice_complete?
    count += 1 if tagline_complete?
    count += 1 if vocabulary_guidelines_complete?
    count += 1 if writing_style_notes_complete?
    count
  end

  private

  def tone_of_voice_complete?
    @brand_language.tone_of_voice.present? &&
      @brand_language.tone_of_voice.is_a?(Hash) &&
      @brand_language.tone_of_voice.any?
  end

  def tagline_complete?
    @brand_language.tagline.present?
  end

  def vocabulary_guidelines_complete?
    @brand_language.vocabulary_guidelines.present? &&
      @brand_language.vocabulary_guidelines.is_a?(Hash) &&
      (@brand_language.vocabulary_guidelines["use"].present? || @brand_language.vocabulary_guidelines[:use].present?)
  end

  def writing_style_notes_complete?
    @brand_language.writing_style_notes.present?
  end
end
