# frozen_string_literal: true

require "active_support"
require "active_support/isolated_execution_state"
require "active_support/cache"
require "active_support/notifications"
require_relative "logger"

module Roast
  module Helpers
    # Intercepts function dispatching to add caching capabilities
    # This module wraps around Raix::FunctionDispatch to provide caching for tool functions
    module FunctionCachingInterceptor
      def dispatch_tool_function(function_name, params)
        start_time = Time.now

        ActiveSupport::Notifications.instrument("roast.tool.execute", {
          function_name: function_name,
          params: params,
        })

        # legacy workflows don't have a configuration
        result = if configuration.blank?
          super(function_name, params)
        else
          function_config = configuration.function_config(function_name)
          if function_config&.dig("cache", "enabled")
            # Call the original function and pass in the cache
            super(function_name, params, cache: Roast::Tools::CACHE)
          else
            Roast::Helpers::Logger.debug("⚠️ Caching not enabled for #{function_name}")
            super(function_name, params)
          end
        end

        execution_time = Time.now - start_time

        ActiveSupport::Notifications.instrument("roast.tool.complete", {
          function_name: function_name,
          execution_time: execution_time,
          cache_enabled: function_config&.dig("cache", "enabled") || false,
        })

        result
      rescue => e
        execution_time = Time.now - start_time

        ActiveSupport::Notifications.instrument("roast.tool.error", {
          function_name: function_name,
          error: e.class.name,
          message: e.message,
          execution_time: execution_time,
        })
        raise
      end
    end
  end
end
