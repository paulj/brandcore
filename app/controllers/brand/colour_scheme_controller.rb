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

  def generate
    # Enqueue the background job
    GeneratePalettesJob.perform_later(@brand)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "palette_suggestions",
          partial: "brand/colour_scheme/palette_loading"
        )
      end
      format.html { redirect_to brand_colour_scheme_path(@brand), notice: "Generating colour palettes..." }
    end
  end

  def apply
    # Parse the palette data from JSON string
    palette_data = JSON.parse(params.require(:palette_data)).with_indifferent_access
    @brand_colour_scheme = @brand.brand_colour_scheme || @brand.create_brand_colour_scheme!

    ActiveRecord::Base.transaction do
      # Clear existing palette colours
      @brand_colour_scheme.palette_colours.destroy_all

      # Create new palette colours from the generated palette
      palette_data[:colors].each_with_index do |color, index|
        palette_colour = @brand_colour_scheme.palette_colours.create!(
          colour_identifier: color[:role],
          name: color[:name],
          base_hex: color[:hex],
          category: categorize_role(color[:role]),
          position: index
        )

        # If we have OKLCH data, we could generate shades here
        # For now, just store the base colour
      end

      # Update generation method
      @brand_colour_scheme.update!(palette_generation_method: "ai_generated")
    end

    @colour_scheme_presenter = BrandColourSchemePresenter.new(@brand_colour_scheme)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("current_palette", partial: "brand/colour_scheme/current_palette", locals: { brand_colour_scheme: @brand_colour_scheme }),
          turbo_stream.replace("section_progress", partial: "shared/section_progress", locals: { presenter: @colour_scheme_presenter })
        ]
      end
      format.html { redirect_to brand_colour_scheme_path(@brand), notice: "Palette applied successfully." }
    end
  rescue StandardError => e
    Rails.logger.error("Palette application error: #{e.message}\n#{e.backtrace.join("\n")}")
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: [ e.message ] }) }
      format.html { redirect_to brand_colour_scheme_path(@brand), alert: "Failed to apply palette: #{e.message}" }
    end
  end

  private

  def brand_colour_scheme_params
    params.require(:brand_colour_scheme).permit(:usage_guidelines, :palette_generation_method)
  end

  def categorize_role(role)
    case role
    when "primary", "secondary"
      role
    when "accent"
      "accent"
    when "background", "text", /neutral/
      "neutral"
    else
      "semantic"
    end
  end
end
