class Brand::TypographyController < Brand::BaseController
  def show
    @brand_typography = @brand.brand_typography || @brand.create_brand_typography!
    @typography_presenter = BrandTypographyPresenter.new(@brand_typography)
  end

  # Search fonts endpoint
  def search_fonts
    query = params[:q] || ""
    fonts = GoogleFontsService.search_fonts(query)
    render json: { fonts: fonts.first(50) } # Limit to 50 results
  end

  # Get font suggestions based on brand vision
  def suggest_fonts
    suggestion_service = FontSuggestionService.new(@brand)
    suggested_fonts = suggestion_service.suggest_fonts(limit: 6)
    render json: { fonts: suggested_fonts }
  end

  # Get fonts by category
  def fonts_by_category
    category = params[:category] || "sans-serif"
    fonts = GoogleFontsService.fonts_by_category(category)
    render json: { fonts: fonts.first(50) }
  end

  def update
    @brand_typography = @brand.brand_typography || @brand.create_brand_typography!
    @typography_presenter = BrandTypographyPresenter.new(@brand_typography)

    # Parse JSONB fields if they come as JSON strings
    parsed_params = brand_typography_params.to_h
    %i[primary_typeface secondary_typeface type_scale line_heights web_font_urls].each do |field|
      if parsed_params[field].present? && parsed_params[field].is_a?(String)
        parsed_params[field] = JSON.parse(parsed_params[field])
      end
    end

    if @brand_typography.update(parsed_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: true }),
            turbo_stream.replace("section_progress", partial: "shared/section_progress", locals: { presenter: @typography_presenter })
          ]
        end
        format.html { redirect_to brand_typography_path(@brand), notice: "Brand typography updated successfully." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: @brand_typography.errors }) }
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @brand_typography.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def brand_typography_params
    params.require(:brand_typography).permit(
      :usage_guidelines,
      primary_typeface: {},
      secondary_typeface: {},
      type_scale: {},
      line_heights: {},
      web_font_urls: []
    )
  end
end
