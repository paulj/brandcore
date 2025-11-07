class Brand::UiController < Brand::BaseController
  def show
    @brand_ui = @brand.brand_ui
  end
end
