class BrandsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  layout "simple", only: [ :new ]
  layout "brand_book", only: [ :show ]

  before_action :set_brand, only: %i[ show edit update destroy ]

  def index
    @brands = Current.user.brands.order(created_at: :desc)
  end

  def show
    # Brand book view - will show skeleton state for incomplete components
  end

  def new
    @brand = Brand.new
    @user = User.new unless authenticated?
  end

  def create
    # If not authenticated, create user first
    unless authenticated?
      @user = User.new(user_params)
      unless @user.save
        @brand = Brand.new(brand_params)
        render :new, status: :unprocessable_entity
        return
      end
      start_new_session_for(@user)
    end

    # Create brand and initialize components in a transaction
    @brand = Brand.new(brand_params)

    if @brand.save
      ActiveRecord::Base.transaction do
        # Create owner membership
        @brand.brand_memberships.create!(user: Current.user, role: "owner")

        # Initialize all component models (they'll be in skeleton state)
        @brand.create_brand_concept!
        @brand.create_brand_name!(name: @brand.name)
        # Note: brand_vision replaced by brand properties system
        @brand.create_brand_logo!
        @brand.create_brand_language!
        @brand.create_brand_colour_scheme!
        @brand.create_brand_typography!
        @brand.create_brand_ui!
      end

      redirect_to brand_path(@brand), notice: "Brand created successfully!"
    else
      @user = User.new unless authenticated?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @brand.update(brand_params)
      redirect_to brand_path(@brand), notice: "Brand updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @brand.destroy
    redirect_to brands_path, notice: "Brand deleted successfully!"
  end

  private

    def set_brand
      @brand = Current.user.brands.find_by!(slug: params[:id])
    end

    def brand_params
      params.require(:brand).permit(:name)
    end

    def user_params
      params.require(:user).permit(:name, :email_address, :password, :password_confirmation)
    end
end
