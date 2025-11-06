class BrandCompletionPresenter
  def initialize(brand)
    @brand = brand
  end

  def completion_percentage
    components = [
      @brand.brand_name,
      @brand.brand_vision,
      @brand.brand_logo,
      @brand.brand_language,
      @brand.brand_colours,
      @brand.brand_typography,
      @brand.brand_ui
    ]
    completed = components.count { |c| c&.completed? }
    (completed.to_f / 7 * 100).round
  end

  def completed_components
    components = []
    components << "name" if @brand.brand_name&.completed?
    components << "vision" if @brand.brand_vision&.completed?
    components << "logo" if @brand.brand_logo&.completed?
    components << "language" if @brand.brand_language&.completed?
    components << "colours" if @brand.brand_colours&.completed?
    components << "typography" if @brand.brand_typography&.completed?
    components << "ui" if @brand.brand_ui&.completed?
    components
  end

  def pending_components
    all = %w[name vision logo language colours typography ui]
    all - completed_components
  end
end
