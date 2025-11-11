class Brand::LogoController < Brand::BaseController
  def show
    @brand_logo = @brand.brand_logo || @brand.create_brand_logo!
    @logo_presenter = BrandLogoPresenter.new(@brand_logo)
  end

  def update
    @brand_logo = @brand.brand_logo || @brand.create_brand_logo!
    @logo_presenter = BrandLogoPresenter.new(@brand_logo)

    # Parse JSONB fields if they come as JSON strings
    parsed_params = brand_logo_params.to_h
    if parsed_params[:usage_guidelines].present? && parsed_params[:usage_guidelines].is_a?(String)
      parsed_params[:usage_guidelines] = JSON.parse(parsed_params[:usage_guidelines])
    end

    if @brand_logo.update(parsed_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: true }),
            turbo_stream.replace("section_progress", partial: "shared/section_progress", locals: { presenter: @logo_presenter })
          ]
        end
        format.html { redirect_to brand_logo_path(@brand), notice: "Brand logo updated successfully." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: @brand_logo.errors }) }
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @brand_logo.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def brand_logo_params
    params.require(:brand_logo).permit(:logo_philosophy, usage_guidelines: {})
  end
end
