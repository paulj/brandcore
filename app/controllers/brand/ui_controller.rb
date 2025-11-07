class Brand::UiController < Brand::BaseController
  def show
    @brand_ui = @brand.brand_ui || @brand.create_brand_ui!
    @ui_presenter = BrandUIPresenter.new(@brand_ui)
  end

  def update
    @brand_ui = @brand.brand_ui || @brand.create_brand_ui!
    @ui_presenter = BrandUIPresenter.new(@brand_ui)

    # Parse JSONB fields if they come as JSON strings
    parsed_params = brand_ui_params.to_h
    %i[button_styles form_elements iconography spacing_system grid_system component_patterns].each do |field|
      if parsed_params[field].present? && parsed_params[field].is_a?(String)
        parsed_params[field] = JSON.parse(parsed_params[field])
      end
    end

    if @brand_ui.update(parsed_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: true }),
            turbo_stream.replace("section_progress", partial: "shared/section_progress", locals: { presenter: @ui_presenter })
          ]
        end
        format.html { redirect_to brand_ui_path(@brand), notice: "Brand UI updated successfully." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: @brand_ui.errors }) }
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @brand_ui.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def brand_ui_params
    params.require(:brand_ui).permit(
      button_styles: {},
      form_elements: {},
      iconography: {},
      spacing_system: {},
      grid_system: {},
      component_patterns: {}
    )
  end
end
