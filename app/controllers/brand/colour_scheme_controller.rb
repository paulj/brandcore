class Brand::ColourSchemeController < Brand::BaseController
  def show
    @brand_colour_scheme = @brand.brand_colour_scheme
  end
end
