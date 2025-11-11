# PaperTrail configuration
PaperTrail.config.enabled = true
PaperTrail.config.has_paper_trail_defaults = {
  on: [ :create, :update, :destroy ]
}

# Track which user made the change
# This will be set in ApplicationController
