class Brand::VisionController < Brand::BaseController
  def show
    @brand_vision = @brand.brand_vision
  end
end
