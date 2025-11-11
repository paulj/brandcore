# frozen_string_literal: true

# Load the idle shutdown support classes
require_relative "../../lib/puma/plugin/idle_shutdown"

# Register the middleware to track request activity
Rails.application.config.middleware.use IdleShutdown::Middleware
