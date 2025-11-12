# frozen_string_literal: true

class SuggestionsController < ApplicationController
  before_action :set_suggestion

  def archive
    @suggestion.archive!

    respond_to do |format|
      format.turbo_stream do
        # Reload the suggestionable to get fresh suggestions
        suggestionable = @suggestion.suggestionable

        # Get the field-specific partial based on field name
        partial_name = "brand/vision/#{@suggestion.field_name}_suggestions"
        target_id = "#{@suggestion.field_name}_suggestions"

        # Build locals based on field type
        # Some fields use an array of suggestions, others use a single suggestion
        locals = if [ "keywords", "brand_personality", "target_audience", "target_markets", "category" ].include?(@suggestion.field_name)
          {
            suggestion: suggestionable.suggestions.pending.for_field(@suggestion.field_name).recent_first.first,
            brand: suggestionable.brand
          }
        else
          {
            suggestions: suggestionable.suggestions.pending.for_field(@suggestion.field_name).recent_first,
            brand: suggestionable.brand
          }
        end

        # Render the updated suggestions list
        render turbo_stream: turbo_stream.replace(
          target_id,
          partial: partial_name,
          locals: locals
        )
      end
      format.html { redirect_back fallback_location: root_path, notice: "Suggestion archived" }
    end
  end

  private

  def set_suggestion
    @suggestion = Suggestion.find(params[:id])
  end
end
