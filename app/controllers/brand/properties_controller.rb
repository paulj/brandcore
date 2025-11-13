# frozen_string_literal: true

# Controller for managing brand properties in a generic, configuration-driven manner.
# Handles creating, updating, accepting, and generating suggestions for any property type.
class Brand::PropertiesController < Brand::BaseController
  before_action :set_property, only: [ :update, :accept, :reject, :destroy ]

  # Create a new property value
  # For single-cardinality: replaces existing current value
  # For multiple-cardinality: adds a new current value
  # POST /brands/:brand_id/properties
  def create
    property_name = params[:property_name]
    value = property_params[:value]
    configuration = PropertyConfiguration.for(property_name)

    if configuration.single?
      # For single-cardinality, move existing to previous and create new
      existing = @brand.properties.for_property(property_name).current.first
      existing&.update!(status: :previous, accepted_at: Time.current)

      @property = @brand.properties.create!(
        property_name: property_name,
        value: value,
        status: :current,
        accepted_at: Time.current
      )
    else
      # For multiple-cardinality, create a new current property
      @property = @brand.properties.create!(
        property_name: property_name,
        value: value,
        status: :current,
        accepted_at: Time.current
      )
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          # Update the field to show the new value
          turbo_stream.replace(
            "#{property_name}_field",
            partial: "brand/properties/fields/#{configuration.input_type}",
            locals: { brand: @brand, property_name: property_name, configuration: configuration }
          ),
          # Show save indicator
          turbo_stream.replace(
            "save_indicator",
            partial: "brand/shared/save_indicator"
          )
        ]
      end
      format.html { redirect_back(fallback_location: brand_vision_path(@brand)) }
    end
  end

  # Update an existing property
  # PATCH /brands/:brand_id/properties/:id
  def update
    @property.update!(property_params)
    configuration = PropertyConfiguration.for(@property.property_name)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "#{@property.property_name}_field",
            partial: "brand/properties/fields/#{configuration.input_type}",
            locals: { brand: @brand, property_name: @property.property_name, configuration: configuration }
          ),
          turbo_stream.replace(
            "save_indicator",
            partial: "brand/shared/save_indicator"
          )
        ]
      end
      format.html { redirect_back(fallback_location: brand_vision_path(@brand)) }
    end
  end

  # Accept a suggestion (makes it the current value)
  # POST /brands/:brand_id/properties/:id/accept
  def accept
    configuration = PropertyConfiguration.for(@property.property_name)
    @property.accept!(cardinality: configuration.cardinality)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          # Update the field with the new current value
          turbo_stream.replace(
            "#{@property.property_name}_field",
            partial: "brand/properties/fields/#{configuration.input_type}",
            locals: { brand: @brand, property_name: @property.property_name, configuration: configuration }
          ),
          # Update the suggestions panel
          turbo_stream.replace(
            "#{@property.property_name}_suggestions",
            partial: "brand/properties/suggestions",
            locals: {
              brand: @brand,
              property_name: @property.property_name,
              configuration: configuration,
              suggestions: @brand.properties.for_property(@property.property_name).suggestions
            }
          )
        ]
      end
      format.html { redirect_back(fallback_location: brand_vision_path(@brand)) }
    end
  end

  # Reject a suggestion
  # POST /brands/:brand_id/properties/:id/reject
  def reject
    @property.reject!
    configuration = PropertyConfiguration.for(@property.property_name)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "#{@property.property_name}_suggestions",
          partial: "brand/properties/suggestions",
          locals: {
            brand: @brand,
            property_name: @property.property_name,
            configuration: configuration,
            suggestions: @brand.properties.for_property(@property.property_name).suggestions
          }
        )
      end
      format.html { redirect_back(fallback_location: brand_vision_path(@brand)) }
    end
  end

  # Delete a property (for removing individual tags from multiple-cardinality properties)
  # DELETE /brands/:brand_id/properties/:id
  def destroy
    property_name = @property.property_name
    configuration = PropertyConfiguration.for(property_name)
    @property.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "#{property_name}_field",
          partial: "brand/properties/fields/#{configuration.input_type}",
          locals: { brand: @brand, property_name: property_name, configuration: configuration }
        )
      end
      format.html { redirect_back(fallback_location: brand_vision_path(@brand)) }
    end
  end

  # Generate AI suggestions for a property
  # POST /brands/:brand_id/properties/generate
  def generate
    property_name = params[:property_name]
    configuration = PropertyConfiguration.for(property_name)

    # Check dependencies
    unless configuration.dependencies_met?(@brand)
      missing = configuration.dependencies.reject do |dep|
        @brand.properties.for_property(dep).current.exists?
      end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "#{property_name}_suggestions",
            partial: "brand/properties/suggestion_error",
            locals: {
              property_name: property_name,
              configuration: configuration,
              error: "Please complete #{missing.map(&:titleize).join(', ')} first"
            }
          )
        end
        format.html do
          flash[:alert] = "Please complete #{missing.map(&:titleize).join(', ')} first"
          redirect_back(fallback_location: brand_vision_path(@brand))
        end
      end
      return
    end

    # Trigger background job
    GeneratePropertySuggestionsJob.perform_later(@brand.id, property_name)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "#{property_name}_suggestions",
          partial: "brand/properties/suggestion_loading",
          locals: { property_name: property_name, configuration: configuration }
        )
      end
      format.html { redirect_back(fallback_location: brand_vision_path(@brand)) }
    end
  end

  private

  def set_property
    @property = @brand.properties.find(params[:id])
  end

  def property_params
    params.require(:brand_property).permit(:value, value: {})
  end
end
