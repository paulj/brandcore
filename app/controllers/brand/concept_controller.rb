class Brand::ConceptController < Brand::BaseController
  def show
    @brand_concept = @brand.brand_concept || @brand.create_brand_concept!
  end

  def update
    @brand_concept = @brand.brand_concept || @brand.create_brand_concept!

    if @brand_concept.update(brand_concept_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: true })
        end
        format.html { redirect_to brand_concept_path(@brand), notice: "Brand concept updated successfully." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: @brand_concept.errors })
        end
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @brand_concept.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def brand_concept_params
    params.require(:brand_concept).permit(:concept)
  end
end
