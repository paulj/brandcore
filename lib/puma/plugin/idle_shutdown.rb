# frozen_string_literal: true

# Puma plugin that monitors request activity and performs a clean shutdown
# after a configurable idle period. Useful for scale-to-zero deployments.
#
# Configuration:
#   plugin :idle_shutdown
#
# Environment variables:
#   IDLE_SHUTDOWN_TIMEOUT - timeout in seconds (default: 1200 = 20 minutes)
#   IDLE_SHUTDOWN_CHECK_INTERVAL - how often to check in seconds (default: 60)

Puma::Plugin.create do
  def start(launcher)
    @launcher = launcher
    @idle_timeout = ENV.fetch("IDLE_SHUTDOWN_TIMEOUT", "1200").to_i
    @check_interval = ENV.fetch("IDLE_SHUTDOWN_CHECK_INTERVAL", "60").to_i

    # Initialize the activity tracker
    ::IdleShutdown::ActivityTracker.instance.reset!

    log "Idle shutdown plugin started (timeout: #{@idle_timeout}s, check interval: #{@check_interval}s)"

    # Start the idle time checker in a background thread
    in_background do
      start_idle_checker
    end
  end

  private

  def start_idle_checker
    log "Starting idle checker thread"

    loop do
      sleep @check_interval

      last_activity = ::IdleShutdown::ActivityTracker.instance.last_request_time
      idle_time = Time.now - last_activity

      log "Idle time: #{idle_time.round(2)}s (threshold: #{@idle_timeout}s)"

      if idle_time >= @idle_timeout
        log "Idle timeout reached (#{idle_time.round(2)}s >= #{@idle_timeout}s). Initiating graceful shutdown..."
        initiate_shutdown
        break
      end
    end
  rescue => e
    log "Error in idle checker: #{e.message}"
    log e.backtrace.join("\n")
  end

  def initiate_shutdown
    log "Shutting down Puma due to inactivity..."

    begin
      # Use Puma's graceful shutdown mechanism
      @launcher.stop
    rescue => e
      log "Error during shutdown: #{e.message}"
      log e.backtrace.join("\n")
    end
  end

  def log(message)
    @launcher.events.log "idle_shutdown: #{message}"
  end
end

# Supporting classes for the idle shutdown plugin
module IdleShutdown
  class ActivityTracker
    include Singleton

    attr_reader :last_request_time

    def initialize
      @last_request_time = Time.now
      @mutex = Mutex.new
    end

    def reset!
      @mutex.synchronize do
        @last_request_time = Time.now
      end
    end

    def record_activity
      @mutex.synchronize do
        @last_request_time = Time.now
      end
    end
  end

  # Rack middleware to track request activity
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      # Record activity for each request
      ActivityTracker.instance.record_activity
      @app.call(env)
    end
  end
end
