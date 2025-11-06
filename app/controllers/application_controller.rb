class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Set PaperTrail whodunnit to track which user made changes
  before_action :set_paper_trail_whodunnit

  private

    def set_paper_trail_whodunnit
      PaperTrail.request.whodunnit = Current.user&.id&.to_s
    end
end
