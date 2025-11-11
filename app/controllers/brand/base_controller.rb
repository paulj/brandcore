class Brand::BaseController < ApplicationController
  layout "brand_book"
  before_action :set_brand

  private

  def set_brand
    @brand = Current.user.brands.find_by!(slug: params[:brand_id])
  end
end
