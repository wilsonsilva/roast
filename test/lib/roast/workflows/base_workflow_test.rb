# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class BaseWorkflowTest < Minitest::Test
      def setup
        @file = fixture_file("test.rb")
      end

      def test_initialize
        Roast::Support::PromptLoader
          .expects(:load_prompt)
          .returns("Test prompt")

        Roast::Tools.expects(:setup_interrupt_handler)

        @workflow = BaseWorkflow.new(@file)
        assert_equal(@file, @workflow.file)
        assert_equal([{ system: "Test prompt" }], @workflow.transcript)
      end

      def test_append_to_final_output_and_final_output
        @workflow = BaseWorkflow.new(@file)
        @workflow.append_to_final_output("Test output")
        assert_equal("Test output", @workflow.final_output)
      end
    end
  end
end
