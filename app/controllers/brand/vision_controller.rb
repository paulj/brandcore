class Brand::VisionController < Brand::BaseController
  def show
    @brand_vision = @brand.brand_vision || @brand.create_brand_vision!
    @vision_presenter = BrandVisionPresenter.new(@brand_vision)
  end

  def update
    @brand_vision = @brand.brand_vision || @brand.create_brand_vision!
    @vision_presenter = BrandVisionPresenter.new(@brand_vision)

    # Parse core_values if they come as JSON strings from JavaScript
    parsed_params = brand_vision_params
    if parsed_params[:core_values].present?
      parsed_params[:core_values] = parsed_params[:core_values].map do |value|
        if value.is_a?(String) && (value.start_with?("{") || value.start_with?("["))
          JSON.parse(value)
        else
          value
        end
      end
    end

    if @brand_vision.update(parsed_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: true }),
            turbo_stream.replace("section_progress", partial: "shared/section_progress", locals: { presenter: @vision_presenter })
          ]
        end
        format.html { redirect_to brand_vision_path(@brand), notice: "Brand vision updated successfully." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: @brand_vision.errors }) }
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @brand_vision.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def brand_vision_params
    params.require(:brand_vision).permit(
      :mission_statement,
      :vision_statement,
      :brand_positioning,
      :target_audience,
      brand_personality: {},
      core_values: [:name, :description, :icon]
    )
  end
end
