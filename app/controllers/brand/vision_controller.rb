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
            turbo_stream.replace("section_progress", partial: "shared/section_progress", locals: { presenter: @vision_presenter }),
            turbo_stream.replace("core_values_section", partial: "brand/vision/core_values", locals: { brand_vision: @brand_vision, brand: @brand })
          ]
        end
        format.html { redirect_to brand_vision_path(@brand), notice: "Brand vision updated successfully." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: @brand_vision.errors }),
            turbo_stream.replace("core_values_section", partial: "brand/vision/core_values", locals: { brand_vision: @brand_vision, brand: @brand })
          ]
        end
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @brand_vision.errors, status: :unprocessable_entity }
      end
    end
  end

  def add_core_value
    @brand_vision = @brand.brand_vision || @brand.create_brand_vision!
    @vision_presenter = BrandVisionPresenter.new(@brand_vision)

    new_value = CoreValue.new(
      name: params[:name],
      description: params[:description],
      icon: params[:icon] || "fa-solid fa-heart"
    )

    if new_value.valid?
      current_values = @brand_vision.core_values || []
      @brand_vision.core_values = current_values + [ new_value ]

      if @brand_vision.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: true }),
              turbo_stream.replace("section_progress", partial: "shared/section_progress", locals: { presenter: @vision_presenter }),
              turbo_stream.replace("core_values_section", partial: "brand/vision/core_values", locals: { brand_vision: @brand_vision, brand: @brand })
            ]
          end
          format.html { redirect_to brand_vision_path(@brand) }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("core_values_section", partial: "brand/vision/core_values", locals: { brand_vision: @brand_vision, brand: @brand, errors: @brand_vision.errors })
          end
          format.html { redirect_to brand_vision_path(@brand), alert: "Failed to add core value." }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("core_values_section", partial: "brand/vision/core_values", locals: { brand_vision: @brand_vision, brand: @brand, errors: new_value.errors })
        end
        format.html { redirect_to brand_vision_path(@brand), alert: "Invalid core value." }
      end
    end
  end

  def remove_core_value
    @brand_vision = @brand.brand_vision || @brand.create_brand_vision!
    @vision_presenter = BrandVisionPresenter.new(@brand_vision)

    index = params[:index].to_i
    current_values = @brand_vision.core_values || []

    if index >= 0 && index < current_values.length
      @brand_vision.core_values = current_values.reject.with_index { |_, i| i == index }

      if @brand_vision.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: true }),
              turbo_stream.replace("section_progress", partial: "shared/section_progress", locals: { presenter: @vision_presenter }),
              turbo_stream.replace("core_values_section", partial: "brand/vision/core_values", locals: { brand_vision: @brand_vision, brand: @brand })
            ]
          end
          format.html { redirect_to brand_vision_path(@brand) }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("core_values_section", partial: "brand/vision/core_values", locals: { brand_vision: @brand_vision, brand: @brand, errors: @brand_vision.errors })
          end
          format.html { redirect_to brand_vision_path(@brand), alert: "Failed to remove core value." }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("core_values_section", partial: "brand/vision/core_values", locals: { brand_vision: @brand_vision, brand: @brand })
        end
        format.html { redirect_to brand_vision_path(@brand), alert: "Invalid index." }
      end
    end
  end

  def generate_core_values
    @brand_vision = @brand.brand_vision || @brand.create_brand_vision!
    @vision_presenter = BrandVisionPresenter.new(@brand_vision)

    generator = CoreValuesGeneratorService.new(
      mission_statement: @brand_vision.mission_statement,
      vision_statement: @brand_vision.vision_statement
    )

    generated_values = generator.generate

    if generated_values.any?
      # Append generated values to existing values
      current_values = @brand_vision.core_values || []
      @brand_vision.core_values = current_values + generated_values

      if @brand_vision.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: true }),
              turbo_stream.replace("section_progress", partial: "shared/section_progress", locals: { presenter: @vision_presenter }),
              turbo_stream.replace("core_values_section", partial: "brand/vision/core_values", locals: { brand_vision: @brand_vision, brand: @brand })
            ]
          end
          format.html { redirect_to brand_vision_path(@brand), notice: "Generated #{generated_values.count} core values." }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace("core_values_section", partial: "brand/vision/core_values", locals: { brand_vision: @brand_vision, brand: @brand, errors: @brand_vision.errors })
          end
          format.html { redirect_to brand_vision_path(@brand), alert: "Failed to save generated core values." }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("core_values_section", partial: "brand/vision/core_values", locals: { brand_vision: @brand_vision, brand: @brand, error: "Unable to generate core values. Please ensure mission or vision statement is filled in." })
        end
        format.html { redirect_to brand_vision_path(@brand), alert: "Unable to generate core values. Please ensure mission or vision statement is filled in." }
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
      :category,
      brand_personality: {},
      core_values: [ :name, :description, :icon ],
      traits: [],
      tone: [],
      markets: [],
      audiences: [],
      keywords: []
    )
  end
end
