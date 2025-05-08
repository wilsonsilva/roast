# frozen_string_literal: true

require "minitest/autorun"
require "mocha/minitest"
require "active_support/core_ext/string/inflections"
require "roast/resources"
require "roast/helpers"
require "roast/tools"
require "roast/workflow/base_step"
require "roast/workflow/base_workflow"

module Roast
  module Workflow
    class BaseStepTest < Minitest::Test
      # Helper to load test fixture file, assuming similar helper exists
      def fixture_file(filename)
        # Adjust this path as needed to match your test/fixtures directory
        File.expand_path("../../fixtures/#{filename}", __dir__)
      end

      def setup
        @file = fixture_file("test.rb")
        @workflow = Roast::Workflow::BaseWorkflow.new(@file)
        @step = Roast::Workflow::BaseStep.new(@workflow)
      end

      def test_initialize_sets_workflow_and_default_model
        assert_equal(@workflow, @step.workflow)
        assert_equal("anthropic:claude-3-7-sonnet", @step.model)
      end

      def test_initialize_accepts_custom_model
        custom_model = "gpt-4"
        step_with_custom_model = Roast::Workflow::BaseStep.new(@workflow, model: custom_model)
        assert_equal(custom_model, step_with_custom_model.model)
      end

      def test_call_adds_prompt_to_transcript_and_calls_chat_completion
        Roast::Helpers::PromptLoader
          .expects(:load_prompt)
          .with(@step, @workflow.file)
          .returns("Test prompt")

        @workflow
          .expects(:chat_completion)
          .returns("Test chat completion response")

        result = @step.call
        assert_equal({ user: "Test prompt" }, @workflow.transcript.last)
        assert_equal("Test chat completion response", result)
      end
    end
  end
end
