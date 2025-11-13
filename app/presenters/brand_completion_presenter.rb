class BrandCompletionPresenter
  def initialize(brand)
    @brand = brand
  end

  def completion_percentage
    components = [
      @brand.brand_name,
      vision_completed?,
      @brand.brand_logo,
      @brand.brand_language,
      @brand.brand_colour_scheme,
      @brand.brand_typography,
      @brand.brand_ui
    ]
    completed = components.count { |c| c == true || c&.completed? }
    (completed.to_f / 7 * 100).round
  end

  def completed_components
    components = []
    components << "name" if @brand.brand_name&.completed?
    components << "vision" if vision_completed?
    components << "logo" if @brand.brand_logo&.completed?
    components << "language" if @brand.brand_language&.completed?
    components << "colours" if @brand.brand_colour_scheme&.completed?
    components << "typography" if @brand.brand_typography&.completed?
    components << "ui" if @brand.brand_ui&.completed?
    components
  end

  def pending_components
    all = %w[name vision logo language colours typography ui]
    all - completed_components
  end

  private

  # Brand vision is complete if we have at least mission, vision, and category
  def vision_completed?
    has_mission = @brand.properties.for_property("mission").current.exists?
    has_vision = @brand.properties.for_property("vision").current.exists?
    has_category = @brand.properties.for_property("category").current.exists?

    has_mission && has_vision && has_category
  end
end
