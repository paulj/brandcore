class Brand::LanguageController < Brand::BaseController
  def show
    @brand_language = @brand.brand_language || @brand.create_brand_language!
    @language_presenter = BrandLanguagePresenter.new(@brand_language)
  end

  def update
    @brand_language = @brand.brand_language || @brand.create_brand_language!
    @language_presenter = BrandLanguagePresenter.new(@brand_language)

    # Parse JSONB fields if they come as JSON strings
    parsed_params = brand_language_params.to_h

    # Handle vocabulary_guidelines which comes as separate use/avoid fields
    if params[:brand_language][:vocabulary_guidelines].present?
      vocab_params = params[:brand_language][:vocabulary_guidelines]
      use_words = vocab_params[:use].present? ? vocab_params[:use].to_s.split(",").map(&:strip).reject(&:blank?) : []
      avoid_words = vocab_params[:avoid].present? ? vocab_params[:avoid].to_s.split(",").map(&:strip).reject(&:blank?) : []
      parsed_params[:vocabulary_guidelines] = {
        "use" => use_words,
        "avoid" => avoid_words
      }
    end

    %i[tone_of_voice messaging_pillars].each do |field|
      if parsed_params[field].present? && parsed_params[field].is_a?(String)
        parsed_params[field] = JSON.parse(parsed_params[field])
      end
    end

    if @brand_language.update(parsed_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: true }),
            turbo_stream.replace("section_progress", partial: "shared/section_progress", locals: { presenter: @language_presenter })
          ]
        end
        format.html { redirect_to brand_language_path(@brand), notice: "Brand language updated successfully." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: @brand_language.errors }) }
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @brand_language.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def brand_language_params
    params.require(:brand_language).permit(
      :tagline,
      :writing_style_notes,
      :example_copy,
      tone_of_voice: {},
      vocabulary_guidelines: {},
      messaging_pillars: []
    )
  end
end
