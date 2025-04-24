# frozen_string_literal: true

require "test_helper"

module Roast
  module Workflow
    class ConfigurationParserTest < ActiveSupport::TestCase
      setup do
        @grading_workflow = Roast::Workflow::ConfigurationParser.new(fixture_file("workflow/workflow.yml"))
      end

      test "initialize with the example workflow" do
        assert_equal Hash, @grading_workflow.configuration.class
        assert_equal @grading_workflow.configuration["steps"].first, "run_coverage"
      end

      test "begin and check number of steps" do
        @grading_workflow
          .expects(:run)
          .with("% ls test/fixtures/files/*test.rb")
          .returns("test/fixtures/files/test.rb")
        @grading_workflow
          .expects(:run)
          .with("run_coverage")
        @grading_workflow
          .expects(:run)
          .with("verify_test_helpers")
        @grading_workflow
          .expects(:run)
          .with("verify_mocks_and_stubs")
        @grading_workflow
          .expects(:run)
          .with("generate_recommendations")
        @grading_workflow.begin!
      end
    end
  end
end
