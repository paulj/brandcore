class Brand::LogoController < Brand::BaseController
  def show
    @brand_logo = @brand.brand_logo
  end
end
