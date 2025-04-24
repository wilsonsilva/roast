# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class BaseStepTest < Minitest::Test
      def setup
        @file = fixture_file("test.rb")
        @workflow = BaseWorkflow.new(@file)
        @step = BaseStep.new(@workflow)
      end

      def test_initialize_sets_workflow_and_model
        # Test with default model
        assert_equal(@workflow, @step.workflow)
        assert_equal("anthropic:claude-3-7-sonnet", @step.model)

        # Test with custom model
        custom_model = "gpt-4"
        step_with_custom_model = BaseStep.new(@workflow, model: custom_model)
        assert_equal(custom_model, step_with_custom_model.model)
      end

      def test_call_adds_prompt_to_transcript_and_calls_chat_completion
        Roast::Support::PromptLoader
          .expects(:load_prompt)
          .with(@step, @workflow.file)
          .returns("Test prompt")

        @workflow
          .expects(:chat_completion)
          .returns("Test chat completion response")

        @step.call
        assert_equal({ user: "Test prompt" }, @workflow.transcript.last)
      end
    end
  end
end
