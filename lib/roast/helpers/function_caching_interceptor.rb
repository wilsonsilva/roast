# frozen_string_literal: true

require "active_support/cache"
require "active_support/notifications"
require_relative "logger"

module Roast
  module Helpers
    # Intercepts function dispatching to add caching capabilities
    # This module wraps around Raix::FunctionDispatch to provide caching for tool functions
    module FunctionCachingInterceptor
      def dispatch_tool_function(function_name, params)
        # legacy workflows don't have a configuration
        return super(function_name, params) if configuration.blank?

        function_config = configuration.function_config(function_name)
        if function_config&.dig("cache", "enabled")
          # Call the original function and pass in the cache
          super(function_name, params, cache: Roast::Tools::CACHE)
        else
          Roast::Helpers::Logger.debug("⚠️ Caching not enabled for #{function_name}")
          super(function_name, params)
        end
      end
    end
  end
end
