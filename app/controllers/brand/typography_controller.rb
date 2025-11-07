class Brand::TypographyController < Brand::BaseController
  def show
    @brand_typography = @brand.brand_typography || @brand.create_brand_typography!
    @typography_presenter = BrandTypographyPresenter.new(@brand_typography)
    @schemes = BrandTypography::SCHEMES
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

    old_scheme = @brand_typography.scheme
    new_scheme = brand_typography_params[:scheme]

    if @brand_typography.update(brand_typography_params)
      # Clean up typefaces that don't match the new scheme
      if new_scheme.present? && old_scheme != new_scheme
        cleanup_invalid_typefaces
        # Reload presenter after cleanup
        @typography_presenter = BrandTypographyPresenter.new(@brand_typography.reload)
      end

      respond_to do |format|
        format.turbo_stream do
          # When scheme changes, replace the typeface panels section
          # Turbo Morph will preserve scroll position
          render turbo_stream: [
            turbo_stream.replace("typeface-panels", partial: "typeface_panels"),
            turbo_stream.replace("section_progress", partial: "shared/section_progress", locals: { presenter: @typography_presenter }),
            turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: true })
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

  # Add a new type scale item
  def add_type_scale_item
    @brand_typography = @brand.brand_typography || @brand.create_brand_typography!
    typeface = @brand_typography.typefaces.find(params[:typeface_id])

    # Add a new empty scale item
    new_scale = TypeScaleItem.new(font_size: "", line_height: "", variant: "Regular", font_weight: "400")
    typeface.type_scale = (typeface.type_scale || []) + [ new_scale ]

    if typeface.save
      @typeface = typeface.reload
      respond_to do |format|
        format.turbo_stream do
          # Remove the "no items" message if it exists, then append the new row
          streams = [
            turbo_stream.remove("no-scale-items-#{@typeface.id}"),
            turbo_stream.before(
              "add-scale-row-#{@typeface.id}",
              partial: "type_scale_item",
              locals: {
                f: nil, # Use standalone form helpers
                typeface: @typeface,
                scale: new_scale,
                index: @typeface.type_scale.length - 1,
                brand: @brand
              }
            )
          ]
          render turbo_stream: streams
        end
        format.html { redirect_to brand_typography_path(@brand) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: typeface.errors }) }
        format.html { redirect_to brand_typography_path(@brand), alert: typeface.errors.full_messages.join(", ") }
      end
    end
  end

  # Remove a type scale item
  def remove_type_scale_item
    @brand_typography = @brand.brand_typography || @brand.create_brand_typography!
    typeface = @brand_typography.typefaces.find(params[:typeface_id])
    index = params[:index].to_i

    # Remove the item at the specified index
    typeface.type_scale = (typeface.type_scale || []).reject.with_index { |_, i| i == index }

    if typeface.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "type-scale-#{typeface.id}",
            partial: "type_scale",
            locals: { typeface: typeface.reload, brand: @brand }
          )
        end
        format.html { redirect_to brand_typography_path(@brand) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: typeface.errors }) }
        format.html { redirect_to brand_typography_path(@brand), alert: typeface.errors.full_messages.join(", ") }
      end
    end
  end

  # Create or update a typeface by role
  def update_typeface
    @brand_typography = @brand.brand_typography || @brand.create_brand_typography!

    # Find typeface by ID if provided, otherwise by role
    if params[:typeface] && params[:typeface][:id].present?
      typeface = @brand_typography.typefaces.find_by(id: params[:typeface][:id])
      unless typeface
        respond_to do |format|
          format.html { redirect_to brand_typography_path(@brand), alert: "Typeface not found." }
          format.json { render json: { error: "Typeface not found" }, status: :not_found }
        end
        return
      end
      role = typeface.role
    else
      role = params[:role]
      # Validate role is allowed by current scheme
      unless @brand_typography.required_roles.include?(role)
        respond_to do |format|
          format.html { redirect_to brand_typography_path(@brand), alert: "Role '#{role}' is not allowed for the current scheme." }
          format.json { render json: { error: "Role '#{role}' is not allowed for the current scheme" }, status: :unprocessable_entity }
        end
        return
      end
      typeface = @brand_typography.typefaces.find_or_initialize_by(role: role)
    end

    # Get parsed params (type_scale will be structured as an array of hashes)
    parsed_params = typeface_params.to_h

    typeface.assign_attributes(parsed_params)
    typeface.role = role unless typeface.persisted? # Ensure role is set for new records

    if typeface.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("typeface-panels", partial: "typeface_panels"),
            turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: true })
          ]
        end
        format.html { redirect_to brand_typography_path(@brand), notice: "Typeface updated successfully." }
        format.json { render json: { success: true, typeface: typeface } }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: typeface.errors }) }
        format.html { redirect_to brand_typography_path(@brand), alert: typeface.errors.full_messages.join(", ") }
        format.json { render json: { error: typeface.errors.full_messages.join(", ") }, status: :unprocessable_entity }
      end
    end
  end

  private

  def cleanup_invalid_typefaces
    allowed_roles = @brand_typography.required_roles
    @brand_typography.typefaces.where.not(role: allowed_roles).destroy_all
  end

  def brand_typography_params
    params.require(:brand_typography).permit(
      :scheme,
      :usage_guidelines,
      typefaces_attributes: [
        :id,
        :role,
        :name,
        :family,
        :category,
        :google_fonts_url,
        :position,
        :_destroy,
        variants: [],
        subsets: [],
        type_scale: [ :font_size, :line_height, :variant, :font_weight ],
        line_heights: {}
      ]
    ).tap do |params|
      # Convert the type scale hash from a form like { "0" => { font_size: ... }, "1" => { font_size: ... } } to an array of hashes
      if params[:typeface_attributes] && scales = params[:typeface_attributes][:type_scale].presence
        if scales.is_a?(Hash) && scales.keys.all? { |key| key.is_a?(String) && key.to_i.to_s == key }
          params[:typeface_attributes][:type_scale] = scales.values
        end
      end
    end
  end

  def typeface_params
    params.require(:typeface).permit(
      :id,
      :role,
      :name,
      :family,
      :category,
      :google_fonts_url,
      :position,
      variants: [],
      subsets: [],
      type_scale: [ :font_size, :line_height, :variant, :font_weight ],
      line_heights: {}
    ).tap do |params|
      # Convert the type scale hash from a form like { "0" => { font_size: ... }, "1" => { font_size: ... } } to an array of hashes
      if scales = params[:type_scale].presence
        if scales.is_a?(ActionController::Parameters) && scales.keys.all? { |key| key.is_a?(String) && key.to_i.to_s == key }
          params[:type_scale] = scales.values
        end
      end
    end
  end
end
