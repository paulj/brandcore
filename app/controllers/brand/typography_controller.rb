class Brand::TypographyController < Brand::BaseController
  def show
    @brand_typography = @brand.brand_typography
  end
end
