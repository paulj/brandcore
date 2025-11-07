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

    # Handle typeface fields - can come as JSON string or hash
    %i[primary_typeface secondary_typeface].each do |field|
      if parsed_params[field].present?
        if parsed_params[field].is_a?(String) && parsed_params[field].strip.present?
          parsed_params[field] = JSON.parse(parsed_params[field])
        elsif parsed_params[field].is_a?(String) && parsed_params[field].strip.empty?
          # Empty string means don't update this field - preserve existing value
          parsed_params.delete(field)
        end
      end
    end

    # Handle other JSONB fields
    %i[type_scale line_heights web_font_urls].each do |field|
      if parsed_params[field].present? && parsed_params[field].is_a?(String)
        parsed_params[field] = JSON.parse(parsed_params[field])
      end
    end

    if @brand_typography.update(parsed_params)
      respond_to do |format|
        format.turbo_stream do
          # Return a redirect response - Turbo will follow it and reload the page
          redirect_to brand_typography_path(@brand), status: :see_other
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
      :primary_typeface,  # Permit as string (will be parsed)
      :secondary_typeface,  # Permit as string (will be parsed)
      type_scale: {},
      line_heights: {},
      web_font_urls: []
    )
  end
end
