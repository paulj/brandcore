class Brand::ColourSchemeController < Brand::BaseController
  def show
    @brand_colour_scheme = @brand.brand_colour_scheme || @brand.create_brand_colour_scheme!
    @colour_scheme_presenter = BrandColourSchemePresenter.new(@brand_colour_scheme)
  end

  def update
    @brand_colour_scheme = @brand.brand_colour_scheme || @brand.create_brand_colour_scheme!
    @colour_scheme_presenter = BrandColourSchemePresenter.new(@brand_colour_scheme)

    if @brand_colour_scheme.update(brand_colour_scheme_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: true }),
            turbo_stream.replace("section_progress", partial: "shared/section_progress", locals: { presenter: @colour_scheme_presenter })
          ]
        end
        format.html { redirect_to brand_colour_scheme_path(@brand), notice: "Colour scheme updated successfully." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: @brand_colour_scheme.errors }) }
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @brand_colour_scheme.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def brand_colour_scheme_params
    params.require(:brand_colour_scheme).permit(:usage_guidelines, :palette_generation_method)
  end
end
