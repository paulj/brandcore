class Brand::LanguageController < Brand::BaseController
  def show
    @brand_language = @brand.brand_language
  end
end
