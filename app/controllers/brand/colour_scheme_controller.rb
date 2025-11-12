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
    brand_vision = @brand.brand_vision

    unless brand_vision
      render json: { error: "Please complete your Brand Vision first to generate colour palettes." }, status: :unprocessable_entity
      return
    end

    begin
      generator = BrandColorPalette::Generator.new(brand_vision)
      result = generator.generate

      # Convert result to JSON-friendly format
      palettes_data = result.palettes.map do |palette|
        {
          scheme: palette.scheme,
          score: palette.score,
          accessible: palette.accessible?,
          colors: palette.colors.map do |color|
            {
              role: color.role,
              name: color.role.to_s.titleize,
              hex: color.hex,
              oklch: color.oklch.to_h,
              rgb: color.rgb.to_h
            }
          end,
          metadata: {
            description: palette.metadata&.description,
            vibe: palette.metadata&.vibe
          },
          accessibility: palette.accessibility&.to_h
        }
      end

      render json: {
        palettes: palettes_data,
        metadata: {
          design_vector: result.metadata.design_vector.to_h,
          primary_traits: result.metadata.primary_traits
        }
      }
    rescue StandardError => e
      Rails.logger.error("Palette generation error: #{e.message}\n#{e.backtrace.join("\n")}")
      render json: { error: "Failed to generate palettes: #{e.message}" }, status: :internal_server_error
    end
  end

  def apply
    palette_data = params.require(:palette)
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
      format.json { head :ok }
    end
  rescue StandardError => e
    Rails.logger.error("Palette application error: #{e.message}\n#{e.backtrace.join("\n")}")
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("save_indicator", partial: "shared/save_indicator", locals: { saved: false, errors: [ e.message ] }) }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
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
