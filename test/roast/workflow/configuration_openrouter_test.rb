# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class ConfigurationOpenRouterTest < Minitest::Test
      def setup
        @workflow_path = File.expand_path("../../fixtures/files/openrouter_workflow.yml", __dir__)
        @configuration = Configuration.new(@workflow_path)
      end

      def test_api_token
        assert_equal("test_openrouter_token", @configuration.api_token)
      end

      def test_api_provider
        assert_equal(:openrouter, @configuration.api_provider)
      end

      def test_openrouter_predicate
        assert(@configuration.openrouter?)
        refute(@configuration.openai?)
      end

      def test_model
        assert_equal("anthropic/claude-3-opus-20240229", @configuration.model)
      end
    end
  end
end
