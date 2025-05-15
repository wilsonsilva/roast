# frozen_string_literal: true

require "test_helper"
require "mocha/minitest"

module Roast
  module Workflow
    class ConfigurationParserOpenRouterTest < Minitest::Test
      def setup
        @workflow_path = File.expand_path("../../fixtures/files/openrouter_workflow.yml", __dir__)
      end

      def test_configure_openrouter_client
        setup_openrouter_constants

        mock_openrouter_client = mock
        OpenRouter::Client.stubs(:new).with(api_key: "test_openrouter_token").returns(mock_openrouter_client)

        ConfigurationParser.new(@workflow_path)
      end

      def setup_openrouter_constants
        unless defined?(::OpenRouter)
          Object.const_set(:OpenRouter, Module.new)
        end

        unless defined?(::OpenRouter::Client)
          OpenRouter.const_set(:Client, Class.new)
        end
      end

      def teardown
        OpenRouter.send(:remove_const, :Client) if defined?(::OpenRouter) && defined?(::OpenRouter::Client)
      end
    end
  end
end
