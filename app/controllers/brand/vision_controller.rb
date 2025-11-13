# frozen_string_literal: true

# VisionController now only handles displaying the vision page.
# All property management is handled by PropertiesController.
class Brand::VisionController < Brand::BaseController
  def show
    # No need to create brand_vision record anymore since we use properties
  end
end
